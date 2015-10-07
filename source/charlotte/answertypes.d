module charlotte.answertypes;

import std.algorithm;
import std.range;
import std.traits :EnumMembers;
import std.conv;

class Operation {
    Place place;
    bool passed;
    Operation before;

    this(Place p, Operation o) {
        place = p;
        passed = false;
        before = o;
    }

    this(Operation o) {
        passed = true;
        before = o;
    }

    string[] getAnswer() {
        string[] s = [this.toString];
        if (before is null) {
            return s;
        }
        return before.getAnswer() ~ s;
    }

	override string toString() const {
		if (passed) return "";
		return place.x.to!string ~ " " ~ place.y.to!string ~ " " ~ (place.flip ? "T " : "H ") ~ (place.rotate * 90).to!string;
	}
}

struct Place {
    bool flip;
    Rotation rotate;
    int x;
    int y;
}

enum Rotation: byte {
    deg0, deg90, deg180, deg270
}

const Place[] allPlaceList = calcAllPlaceList;
Place[] calcAllPlaceList() pure {
    Place[] ls;
    foreach (bool f; [true, false]) {
        foreach (Rotation r; [EnumMembers!Rotation]) {
            foreach (int x; iota(-7, 39)) {
                foreach (int y; iota(-7, 39)) {
                    ls ~= Place(f, r, x, y);
                }
            }
        }
    }
	ls.reverse();
    return ls;
}



unittest {
    auto p = Place(true, Rotation.deg0, 1, 2);
}
