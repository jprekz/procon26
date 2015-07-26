module field;

import std.ascii;
import std.format;

alias immutable(int[32]) Field;

string toString(Field f) pure {
	string str;
	foreach (b; f) {
		str ~= format("%032b", b);
		str ~= newline;
	}
	return str;
}

bool getbit(Field f, int x, int y) pure {
	if (x < 0 || 31 < x || y < 0 || 31 < y) return false;
	return 0 != (f[y] & (0x80000000 >> x));
}

Field complement(Field f) pure {
	int[32] output;
	for (int i; i < 32; i++) {
		output[i] = ~f[i];
	}
	return output;
}

bool isOverlap(Field a, Field b) pure {
	for (int i; i < 32; i++) {
		if ((a[i] & b[i]) != 0) return true;
	}
	return false;
}

Field overlap(Field a, Field b) pure {
	int[32] output;
	for (int i; i < 32; i++) {
		output[i] = a[i] | b[i];
	}
	return output;
}

Field bordering(Field f) pure {
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

int countEmptyCells(Field f) pure {
	int output;
	for (int x; x < 32; x++) {
		for (int y; y < 32; y++) {
			if (!f.getbit(x, y)) output++;
		}
	}
	return output;
}
