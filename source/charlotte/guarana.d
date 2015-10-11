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
    const int stonesZukuTotal;
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
        stonesZukuTotal = analyzed.stone.map!(a => a.zuku).reduce!("a+b");
        allPlacedStone = calcAllPlacedStone;
    }

    auto calcAllPlacedStone() {
        PlacedStone[][] aps;
        Place[][] placesShuffle = analyzed.places.map!dup.array;
        aps = new PlacedStone[][stonesTotal];
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

    int start(int skipCount) {
        int[][] allPlacedStoneOrder = new int[][stonesTotal];
        foreach (stoneId, ref int[] order; allPlacedStoneOrder) {
            order = iota(allPlacedStone[stoneId].length).map!(a => a.to!int).array;
        }

        bool passSmallStone = analyzed.stone.map!(a => a.zuku).filter!(a => a < 3).array.length < stonesTotal / 5;
        writeln(passSmallStone ? "pass small tones" : "don't pass small tones");

        int searchWidth = 0, searchDepth = 0;
        LOOP: while (1) {
            searchWidth += 2;
            searchDepth += 4;
            if (searchWidth > 100) return bestScore;
            writeln("Guarana Search: ", searchWidth, " * ", searchDepth);

            int passedZuku = fieldCells - stonesZukuTotal;
            State state = new State(problem.field);

            foreach (stoneId, ref ans; state.answerLs) {
                if (passSmallStone && analyzed.stone[stoneId].zuku < 3 && !state.first) continue;

                int[] candidate;
                int[] scores =
                    iota(allPlacedStone[stoneId].length)
                    .map!(i => state.eval(allPlacedStone[stoneId][i], stoneId.to!short))
                    .array;
                allPlacedStoneOrder[stoneId].sort!((a, b) => scores[a] > scores[b]);
                foreach (i; allPlacedStoneOrder[stoneId]) {
                    if (rndPer(searchWidth / 4)) continue;
                    PlacedStone s = allPlacedStone[stoneId][i];
                    if (state.canPut(s, stoneId.to!short)) {
                        candidate ~= i;
                        if (candidate.length >= searchWidth) break;
                    }
                }
                int[] pZero = new int[candidate.length];
                foreach (j, i; parallel(candidate)) {
                    PlacedStone ps = allPlacedStone[stoneId][i];
                    State nextState = state.dup;
                    nextState.put(ps, stoneId.to!short);
                    pZero[j] = nextState.possibilityZero(stoneId.to!int, searchDepth);
                    pZero[j] += nextState.pinhole * 2;
                }
                int index = -1, min = 1024;
                foreach (i, z; pZero) {
                    if (min > z) {
                        index = i.to!int;
                        min = z;
                    }
                }
                if (index != -1) {
                    state.put(allPlacedStone[stoneId][candidate[index]], stoneId.to!short);
                    ans = candidate[index].to!int;
                    write(stoneId);
                } else {
                    write(".");
                    passedZuku += analyzed.stone[stoneId].zuku;
                    if (passedZuku > bestScore) {
                        writeln(" SKIP");
                        skipCount--;
                        if (skipCount <= 0) return bestScore;
                        continue LOOP;
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
        assert(0);
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
            answerLs = new int[stonesTotal];
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

        ubyte[32][32] possibilityMap(int pos, int depth = 256) {
            ubyte[32][32] pMap;
            foreach (stoneId; pos .. min(stonesTotal, pos + depth)) {
                if (answerLs[stoneId] != -1) continue;
                if (analyzed.stone[stoneId].zuku == 1) continue;
                bool[32][32] sMap;
                L1: foreach (ps; allPlacedStone[stoneId]) {
                    foreach (y, ff; ps.field) foreach (x, b; ff) {
                        if (!b) continue;
                        if (map[y][x] != -1) continue L1;
                    }
                    foreach (y, ff; ps.field) foreach (x, b; ff) {
                        if (!b) continue;
                        sMap[y][x] = true;
                    }
                }
                foreach (y, ff; sMap) foreach (x, b; ff) {
                    if (!b) continue;
                    pMap[y][x]++;
                }
            }
            return pMap;
        }

        int possibilityZero(int pos, int depth = 256) {
            int countZero = 0;
            ubyte[32][32] pMap = possibilityMap(pos, depth);
            foreach (y, ff; pMap) foreach (x, b; ff) {
                if (pMap[y][x] == 0 && map[y][x] == -1) countZero++;
            }
            return countZero;
        }

        int pinhole() const {
            int countP = 0;
            foreach (y, ff; map) foreach (x, b; ff) {
                if (b != -1) continue;
    			if (((y == 0)  || map[y - 1][x] != -1) &&
    				((x == 0)  || map[y][x - 1] != -1) &&
    				((x == 31) || map[y][x + 1] != -1) &&
    				((y == 31) || map[y + 1][x] != -1)) {
                        countP++;
                }
            }
            return countP;
        }
    }
}
