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
	if (x < 0 || 31 < x || y < 0 || 31 < y) return false;
	return 0 != (f[y] & (0x80000000 >> x));
}

pure Field complement(Field f) {
	int[32] output;
	for (int i; i < 32; i++) {
		output[i] = ~f[i];
	}
	return output;
}

pure bool isOverlap(Field a, Field b) {
	for (int i; i < 32; i++) {
		if ((a[i] & b[i]) != 0) return true;
	}
	return false;
}

pure Field overlap(Field a, Field b) {
	int[32] output;
	for (int i; i < 32; i++) {
		output[i] = a[i] | b[i];
	}
	return output;
}

pure Field bordering(Field f) {
	int[32] output;
	for (int x; x < 32; x++) {
		for (int y; y < 32; y++) {
			if (f.getbit(x, y)) continue;
			if (f.getbit(x, y - 1) || f.getbit(x - 1, y) || f.getbit(x + 1, y) || f.getbit(x, y + 1)) {
				output[y] += 0x80000000 >> x;
			}
		}
	}
	return output;
}

pure int countEmptyCells(Field f) {
	int output;
	for (int x; x < 32; x++) {
		for (int y; y < 32; y++) {
			if (!f.getbit(x, y)) output++;
		}
	}
	return output;
}
