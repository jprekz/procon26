module charlotte.guarana;

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
import charlotte.toimpl;

bool rndPer(int p) {
    return uniform(0, 100) < p;
}

struct PlacedStone {
    Field field;
    Place place;
}

class Guarana {
    const Problem problem;
    const void delegate(string[], int, int) findAnswerDelegate;
    const Analyzer analyzed;
    const int fieldCells;
    const int stonesTotal;
    const PlacedStone[][] allPlacedStone;
    StopWatch sw;

    this(string problemName, void delegate(string[], int, int) findAnswer) {
        sw.start();
		problem = problemRead(problemName);
        findAnswerDelegate = findAnswer;
        analyzed = new Analyzer(problem).calcStone.calcAllPlace;
        writeln(sw.peek().msecs,"msec");
        fieldCells = problem.field.countEmptyCells;
        stonesTotal = problem.stone.length.to!int;
        allPlacedStone = calcAllPlacedStone;
    }

    auto calcAllPlacedStone() {
        PlacedStone[][] aps;
        Place[][] placesShuffle = analyzed.places.map!dup.array;
        aps = new PlacedStone[][problem.stone.length];
        foreach (i, s; problem.stone) {
            foreach (p; placesShuffle[i]) {
                if (analyzed.stone[i].isSkip(p)) continue;
                Stone stoneRotated = s.transform(p.flip, p.rotate);
                if (stoneRotated.isProtrude(p.x, p.y)) continue;
                Field placedStone = stoneRotated.putStoneOnField(p.x, p.y);
                if (placedStone.isWrap(problem.field)) {
                    continue;
                }
                aps[i] ~= PlacedStone(placedStone, p);
            }
        }
        return aps;
    }

    void start() {
        foreach (threadId; parallel(iota(threadsPerCPU), 1)) {
            int[][] allPlacedStoneOrder = new int[][problem.stone.length];
            foreach (stoneId, ref int[] order; allPlacedStoneOrder) {
                order = iota(allPlacedStone[stoneId].length).map!(a => a.to!int).array;
            }

            while (1) {
                State state = new State(problem.field);

                foreach (stoneId, ref ans; state.answerLs) {
                    int[] scores =
                        iota(allPlacedStone[stoneId].length)
                        .map!(i => state.eval(allPlacedStone[stoneId][i], stoneId.to!short))
                        .array;
                    allPlacedStoneOrder[stoneId].sort!((a, b) => scores[a] > scores[b]);
                    if (analyzed.stone[stoneId].zuku < 3 && !state.first) continue;
                    foreach (i; allPlacedStoneOrder[stoneId]) {
                        PlacedStone s = allPlacedStone[stoneId][i];
                        if (state.canPut(s, stoneId.to!short)) {
                            state.put(s, stoneId.to!short);
                            ans = i.to!int;
                            break;
                        }
                    }
                }
                foreach (stoneId, ref ans; state.answerLs) {
                    if (state.answerLs[stoneId] != -1) continue;
                    foreach (i, PlacedStone s; allPlacedStone[stoneId]) {
                        if (state.canPut(s, stoneId.to!short)) {
                            state.put(s, stoneId.to!short);
                            ans = i.to!int;
                            break;
                        }
                    }
                }
                findAnswer(state);
            }
        }
    }

	int bestScore = 1024;
    int bestStones = 257;
    void findAnswer(State state) {
        string[] answer;
        int score = fieldCells, usingStones = 0;
        foreach (stoneId, ans; state.answerLs) {
            if (ans == -1) answer ~= "";
            else {
                answer ~= allPlacedStone[stoneId][ans].place.toString;
                score -= analyzed.stone[stoneId].zuku;
                usingStones++;
            }
        }
        writeln("Score:", score, "  Stones:", usingStones, "\t", sw.peek().msecs, "msec");
        if (bestScore <= score) return;
        if (bestScore == score && bestStones <= usingStones) return;
        bestScore = score;
        bestStones = usingStones;
        writeln(state);
        writeln("Score:", score, "  Stones:", usingStones, "\t", sw.peek().msecs, "msec");
        findAnswerDelegate(answer, score, usingStones);
	}



    class State {
        //-2障害物 -1空白 0~石
        short[32][32] map;
        int[] answerLs;
        bool first = true;

        this(Field f) {
            foreach (y, ff; f) foreach(x, b; ff) {
                map[y][x] = (b) ? -2 : -1;
            }
            answerLs = new int[problem.stone.length];
            foreach (ref i; answerLs) i = -1;
        }
        this(short[32][32] m, int[] ls, bool f) {
            map = m;
            answerLs = ls.dup;
            first = f;
        }
        State dup() {
            return new State(map, answerLs, first);
        }
        override string toString() const {
            char[] str;
            foreach (a; map) {
                foreach (n; a) {
                    string block = toImpl16(n);
                    while (block.length < 2) block = '0'~block;
                    if (n == -1) block = "  ";
                    if (n == -2) block = "[]";
                    str ~= block;
                }
                str ~= '\n';
            }
            return str.idup;
        }

        bool canPut(ref const PlacedStone ps, short stoneId) {
            foreach (y, ff; ps.field) foreach(x, b; ff) {
                if (!b) continue;
                if (map[y][x] != -1) return false;
            }
            if (!first) {
                foreach (y, ff; ps.field.bordering) foreach(x, b; ff) {
                    if (!b) continue;
                    if (map[y][x] >= 0 && map[y][x] < stoneId) return true;
                }
                return false;
            }
            return true;
        }

        void put(ref const PlacedStone ps, short stoneId) {
            foreach (y, ff; ps.field) foreach(x, b; ff) {
                if (!b) continue;
                map[y][x] = stoneId;
            }
            first = false;
        }

        int eval(ref const PlacedStone ps, short stoneId) {
            int score = 0;
            foreach (y, ff; ps.field.bordering) foreach(x, b; ff) {
                if (!b) continue;
                if (map[y][x] >= 0 && map[y][x] < stoneId) score++;
            }
            return score;
        }
    }
}
