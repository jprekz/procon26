module charlotte.problemanalyzer;

import std.stdio;
import std.array;
import std.range;
import std.algorithm;
import std.typecons;
import std.conv;
import std.parallelism;

import charlotte.answertypes;
import charlotte.problemtypes;

class Analyzer {
    const Problem problem;
    StoneAnalyzed[] stone;
    Place[][] places;

    public this(const Problem p) {
        problem = p;
    }

    public auto calcStone() {
        stone = problem.stone.map!(a => StoneAnalyzed(a)).array;
        return this;
    }

    public auto calcAllPlace() {
        places = zip(problem.stone, stone).map!(a => calcAllPlaceByStone(a.expand)).array;
        return this;
    }

    private Place[] calcAllPlaceByStone(Stone s, StoneAnalyzed a) {
        Place[] ls = new Place[allPlaceList.length];
        bool[] f = new bool[allPlaceList.length];
        foreach (i, p; parallel(allPlaceList)) {
            if (a.isSkip(p)) continue;
            Stone stoneRotated = s.transform(p.flip, p.rotate);
            if (stoneRotated.isProtrude(p.x, p.y)) continue;
            Field placedStone = stoneRotated.putStoneOnField(p.x, p.y);
            if (placedStone.isWrap(problem.field)) continue;
            ls[i] = p;
            f[i] = true;
        }
        return zip(ls, f).filter!(a => a[1]).map!(a => a[0]).array;
    }
}

struct StoneAnalyzed {
    int width;
    int height;
    int zuku;
    int neighbor;
    bool skipFlip;
    bool skipR180;
    bool skipR90;

    bool isSkip(Place p) const {
        if ((skipFlip && p.flip) ||
            ((skipR90 || skipR180) && p.rotate == 3) ||
            (skipR90 && p.rotate == 1) ||
            (skipR180 && p.rotate == 2)) {
            return true;
        }
        return false;
    }

    this(int w, int h, int z, int n, bool f, bool a, bool b) {
        width = w; height = h; zuku = z; neighbor = n;
        skipFlip = f; skipR180 = a; skipR90 = b;
    }
    this(Stone s) {
        Stone normalized = s.normalize;

        height = normalized.dup.count!(a => a.reduce!("a||b")).to!int;
        width = normalized.transform(true, 3).dup.count!(a => a.reduce!("a||b")).to!int;
        zuku = s.countCells;
        neighbor = s.putStoneOnField(1, 1).bordering.countCells;

        skipFlip = false;
        for (int i; i < 4; i++) {
            if (normalized == normalized.transform(true, i).normalize) {
                skipFlip = true;
            }
        }
        skipR90 = false;
        skipR180 = false;
        if (normalized == normalized.transform(false, 1).normalize) {
            skipR90 = true;
            skipR180 = true;
        } else if (normalized == normalized.transform(false, 2).normalize) {
            skipR180 = true;
        }
    }
}

Stone normalize(Stone s) {
    Stone normalized = s;
    for (int i; i < 2; i++) {
        while (!normalized[0].reduce!("a||b")) {
            normalized = normalized[1..$] ~ normalized[0];
        }
        normalized = normalized.transform(true, 3);
    }
    return normalized;
}



unittest {
    Stone s = Stone([
        [0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0],
        [0,1,0,0,1,1,0,0],
        [0,1,0,0,1,1,0,0],
        [0,1,1,1,1,1,0,0],
        [0,0,0,0,1,1,0,0],
        [0,0,0,0,1,1,0,0],
        [0,0,0,0,0,0,0,0]
    ]);
    assert(StoneAnalyzed(s) == StoneAnalyzed(5, 5, 15, 21, false, false, false));
    Stone d = Stone([
        [0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0],
        [0,0,0,0,1,0,0,0],
        [0,0,1,1,1,0,0,0],
        [0,0,0,1,1,1,0,0],
        [0,0,0,1,0,0,0,0],
        [0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0]
    ]);
    assert(StoneAnalyzed(d) == StoneAnalyzed(4, 4, 8, 12, false, true, true));
}
