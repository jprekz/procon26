module charlotte.stoneanalyzer;

import std.stdio;
import std.array;
import std.range;
import std.algorithm;
import std.typecons;
import std.conv;

import charlotte.answertypes;
import charlotte.problemtypes;

class Analyzer {
    const Problem problem;
    StoneAnalyzed[] stone;
    FieldAnalyzed field;

    this(const Problem p) {
        problem = p;
    }

    auto calcStone() {
        stone = problem.stone.map!analyzeStone.array;
        return this;
    }

    auto calcField() {
        field = FieldAnalyzed(1);
        return this;
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
            (skipR90 && (p.rotate == 1 || p.rotate == 3)) ||
            (skipR180 && p.rotate == 2)) {
            return true;
        }
        return false;
    }
}
struct FieldAnalyzed {int dummy;}

StoneAnalyzed analyzeStone(Stone s) {
    Stone normalized = s.normalize;

    int height = normalized.dup.count!(a => a.reduce!("a||b")).to!int;
    int width = normalized.transform(true, 3).dup.count!(a => a.reduce!("a||b")).to!int;

    int zuku = s.countCells;
    int neighbor = s.putStoneOnField(1, 1).bordering.countCells;

    bool skipFlip = false;
    for (int i; i < 4; i++) {
        if (normalized == normalized.transform(true, i).normalize) {
            skipFlip = true;
        }
    }
    bool skipR90 = false;
    bool skipR180 = false;
    if (normalized == normalized.transform(false, 1).normalize) {
        skipR90 = true;
        skipR180 = true;
    } else if (normalized == normalized.transform(false, 2).normalize) {
        skipR180 = true;
    }

    return StoneAnalyzed(
        width, height, zuku, neighbor,
        skipFlip, skipR180, skipR90
    );
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
    assert(s.analyzeStone == StoneAnalyzed(5, 5, 15, 21, false, false, false));
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
    assert(d.analyzeStone == StoneAnalyzed(4, 4, 8, 12, false, true, true));
}
