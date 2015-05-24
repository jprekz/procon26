module field;

import std.ascii;
import std.format;

alias immutable(int[32]) Field;

pure string toString(Field f) {
	string str;
	foreach (b; f) {
		str ~= format("%032b", b);
		str ~= newline;
	}
	return str;
}

pure bool getbit(Field f, int x, int y) {
	return 0 != (f[y] & (0x80000000 >> x));
}
