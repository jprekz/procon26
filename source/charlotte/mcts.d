module charlotte.mcts;

import std.stdio;
import std.range;
import std.algorithm;
import std.typecons;
import std.parallelism;
import std.datetime;
import std.conv;
import std.math;
import std.random;
import core.cpuid;

import charlotte.answertypes;
import charlotte.problemreader;
import charlotte.problemtypes;
import charlotte.problemanalyzer;

class MCTS {
    const Problem problem;
    const void delegate(string[], int, int) findAnswerDelegate;
    const Analyzer analyzed;
    const int fieldCells;
    const int stonesTotal;
    StopWatch sw;

    this(string problemName, void delegate(string[], int, int) findAnswer) {
        sw.start();
		problem = problemRead(problemName);
        findAnswerDelegate = findAnswer;
        analyzed = new Analyzer(problem).calcStone.calcAllPlace;
        writeln(sw.peek().msecs,"msec");
        fieldCells = problem.field.countEmptyCells;
        stonesTotal = problem.stone.length.to!int;
    }

    class Node {
        int depth;
        Field nowField;
        Field placeableMap;
        bool first;
        Operation searchingAnswer;
        int usingStones;
        this(int d, Field n, Field p, bool f, Operation s, int u) {
            depth = d; nowField = n; placeableMap = p;
            first = f; searchingAnswer = s; usingStones = u;
        }
        Node[] calcChildNodes() {
            Node[] ls;
            mixin findNext!(this, allPlaceList, 0, delegate (n){ ls ~= n; });
            findNext();
            return ls;
        }
    }

    void findNext(alias n, alias pRange, int finds, alias findNode)() {
        static if (finds > 1) int count = finds;
        foreach (p; pRange) {
            if (analyzed.stone[n.depth].isSkip(p)) continue;

            // 石を回転
            Stone stoneRotated = problem.stone[n.depth].transform(p.flip, p.rotate);

            // 石がフィールド外にはみ出さないか
            if (stoneRotated.isProtrude(p.x, p.y)) continue;

            // 石をField座標に配置
            Field placedStone = stoneRotated.putStoneOnField(p.x, p.y);

            // 石が置ける位置にあるか
            if ((placedStone.isWrap(n.nowField)) ||
                !(placedStone.isWrap(n.placeableMap))) {
                continue;
            }

            findNode(new Node(
                n.depth + 1,
                n.nowField | placedStone,
                (n.first) ? placedStone.bordering
                    : (n.placeableMap | placedStone.bordering),
                false,
                new Operation(p, n.searchingAnswer),
                n.usingStones + 1
            ));
            static if (finds == 1) return;
            else static if (finds == 0) {}
            else {
                count--;
                if (count == 0) return;
            }
        }
        findNode(new Node(
            n.depth + 1,
            n.nowField,
            n.placeableMap,
            n.first,
            new Operation(n.searchingAnswer),
            n.usingStones
        ));
    }

    class MCTNode {
        Node node;
        MCTNode parentNode;
        double score = 0.8;
        int visits = 0;
        bool expanded = false;
        MCTNode[] childNodes = MCTNode[].init;
        this(Node n, MCTNode p) {
            node = n;
            parentNode = p;
        }
        void expand() {
            if (expanded) return;
            Node[] cNode = node.calcChildNodes;
            foreach (i, n; cNode) {
                if (cNode.length > 100 && i % (cNode.length/100+1) != 0) continue;
                childNodes ~= new MCTNode(n, this);
            }
            writeln("expand[",node.depth,"]->",cNode.length,"\t",sw.peek().msecs,"msec");
            expanded = true;
        }
        MCTNode selectNext() {
            assert (expanded);
            auto totalVisits = visits;
            auto values = childNodes.map!((n) {
                const c = 0.4;
                return n.score + c * sqrt(log(totalVisits) / n.visits).to!double;
            }).array;
            int index = 0; double max = 0.0;
            foreach (i, v; values) {
                if (max < v) {
                    max = v;
                    index = i.to!int;
                }
            }
            return childNodes[index];
        }
        bool isExpandedCond() {
            const int threshold = 12 - stonesTotal / 32;
            return visits >= threshold;
        }
        void updateUpwards(int scoreUpdate) {
            double normalizedScore = 1.0 - scoreUpdate.to!double / fieldCells;
            visits++;
            score = (score * visits + normalizedScore) / (visits + 1);
            if (parentNode !is null) parentNode.updateUpwards(scoreUpdate);
        }
    }

    void start(int bs = 1024) {
        bestScore = bs;
        MCTNode root = new MCTNode(new Node( 0,
            problem.field,
            problem.field.inv,
            true,
            null,
            0
        ), null);
        root.expand;
        foreach (i; parallel(iota(threadsPerCPU), 1)) {
            Place[][] placesShuffle = analyzed.places.map!dup.array;
            while (true) {
                MCTNode now = root;
                while (now.expanded) now = now.selectNext;
                if (now.node.depth == stonesTotal) break;
                if (now.isExpandedCond) {
                    synchronized { now.expand; }
                    now = now.childNodes[0];
                }
                now.visits++;
                int score = playout(now.node, placesShuffle);
                now.visits--;
                //writeln(now.node.depth,",\t",score,",\t",sw.peek().msecs,"msec");
                now.updateUpwards(score);
            }
        }
    }

    int playout(Node firstNode, Place[][] places) {
        Node now = firstNode;
        while (true) {
            if (now.depth >= stonesTotal) {
                end(now);
                return now.nowField.countEmptyCells;
            }
            Place[] rndPlaceList = places[now.depth];
            rndPlaceList.randomShuffle;
            mixin findNext!(now, rndPlaceList, 1, delegate (n){ now = n; });
            findNext();
        }
    }

    int bestScore = 1024;
    int bestStones = 257;
    void end(ref const Node n) {
        int score = n.nowField.countEmptyCells;
        if (bestScore < score) return;
        if (bestScore == score && bestStones <= n.usingStones) return;
        bestScore = score;
        bestStones = n.usingStones;
        writeln(n.nowField.toString,"Score:", score, "  Stones:", n.usingStones, "\t", sw.peek().msecs, "msec");
        synchronized {
            if (bestScore < score) return;
            if (bestScore == score && bestStones < n.usingStones) return;
            findAnswerDelegate(n.searchingAnswer.getAnswer(), score, n.usingStones);
        }
    }
}



class MC : MCTS {
    this(string problemName, void delegate(string[], int, int) findAnswer) {
        super(problemName, findAnswer);
    }

    override void start(int bs = 1024) {
        bestScore = bs;
        foreach (i; parallel(iota(threadsPerCPU), 1)) {
            Place[][] placesShuffle = analyzed.places.map!dup.array;
            while (true) {
                int score = playout( new Node( 0,
                    problem.field,
                    problem.field.inv,
                    true,
                    null,
                    0
                ), placesShuffle);
                //writeln(score,",\t",sw.peek().msecs,"msec");
            }
        }
    }
}



class MCTSP(int N) : MCTS {
    this(string problemName, void delegate(string[], int, int) findAnswer) {
        super(problemName, findAnswer);
    }

    override int playout(Node firstNode, Place[][] places) {
        Node now = firstNode;
        while (true) {
            if (now.depth >= stonesTotal) {
                end(now);
                return now.nowField.countEmptyCells;
            }
            Place[] rndPlaceList = places[now.depth];
            Node[] next = [];
            rndPlaceList.randomShuffle;
            mixin findNext!(now, rndPlaceList, N, delegate (n){ next ~= n; });
            findNext();
            int[] ss = next.map!(n => eval(n)).array;
            int index, max = -1;
            foreach (i, v; ss) {
                if (max < v) {
                    max = v;
                    index = i.to!int;
                }
            }
            now = next[index];
        }
    }

    int eval(Node n) {
        if (n.searchingAnswer.passed) return 0;
        Place p = n.searchingAnswer.place;
        Stone stoneRotated = problem.stone[n.depth-1].transform(p.flip, p.rotate);
        Field placedStone = stoneRotated.putStoneOnField(p.x, p.y);
        return (n.nowField & placedStone.bordering).countCells;
    }
}
