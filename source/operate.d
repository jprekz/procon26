module operate;

import std.ascii;
import std.conv;

class Operate {
	public:
	bool passed;
	int x;
	int y;
	bool invert;
	int rotate;
	Operate before;
	this(bool p, int xx, int yy, bool inv, int r, Operate o) {
		passed = p;
		x = xx;
		y = yy;
		invert = inv;
		rotate = r;
		before = o;
	}

	const Operate next(Operate b) {
		return new Operate(passed, x, y, invert, rotate, b);
	}

	override const string toString() {
		if (passed) return newline;
		return x.to!string ~ " " ~ y.to!string ~ " " ~ (invert ? "T " : "H ") ~ (rotate * 90).to!string;
	}

	string getAnswerFormat() {
		if (before is null) return this.toString;
		return before.getAnswerFormat() ~ newline ~ this.toString;
	}

	static Operate[] calcAllOperateList() {
		Operate[] ls;
		bool[2] inv = [false, true];
		for (int x; x < 32; x++) {
			for (int y; y < 32; y++) {
				foreach (b; inv) {
					for (int r; r < 4; r++) {
						ls ~= new Operate(false, x, y, b, r, null);
					}
				}
			}
		}
		ls ~= new Operate(true, 0, 0, false, 0, null);
		return ls;
	}
}
