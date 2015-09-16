module charlotte.answertypes;

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

enum Rotation {
    deg0, deg90, deg180, deg270
}

unittest {
    auto p = Place(true, Rotation.deg0, 1, 2);
}
