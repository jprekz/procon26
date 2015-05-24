module field;

import std.ascii;
import std.format;

alias immutable(_Field) Field;
private immutable struct _Field {
	int[32] bitArr;

	pure nothrow this(int[32] bits) {
		bitArr = bits;
	}

	const void toString(scope void delegate(const(char)[]) sink) {
		foreach (b; bitArr) {
			sink(format("%032b", b));
			sink(newline);
		}
	}

	pure bool getbit(int x, int y) {
		return 0 != (bitArr[y] & (0x80000000 >> x));
	}
}
