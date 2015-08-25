module dfs.stone;

import std.ascii;
import std.format;

alias immutable(byte[8]) Stone;

string toString(Stone s) pure {
	string str;
	foreach (b; s) {
		str ~= format("%08b", b);
		str ~= newline;
	}
	return str;
}

bool getbit(Stone s, int x, int y) pure {
	return 0 != (s[y] & (0b10000000 >>> x));
}

// invert ... 反転するか否か
// rotate(0 ~ 3) ... 引数 * 90度 右に回転
Stone transform(Stone s, bool invert, int rotate) pure {
	assert(rotate >= 0 && rotate < 4);

	if (rotate == 0) {
		return invert ? s.flipHorizontal : s;
	} else if (rotate == 1) {
		return invert ? s.flipHorizontal.rotateRight : s.rotateRight;
	} else if (rotate == 2) {
		return invert ? s.flipVertical : s.flipVertical.flipHorizontal;
	} else if (rotate == 3) {
		return invert ? s.flipHorizontal.rotateLeft : s.rotateLeft;
	}
	assert(0);
}

// 左右反転
private Stone flipHorizontal(Stone s) pure {
	byte[8] output;
	for (int i; i < 8; i++) {
		output[i] = bitflip8(s[i]);
	}
	return output;
}

// 上下反転
private Stone flipVertical(Stone s) pure {
	byte[8] output;
	for (int i; i < 8; i++) {
		output[i] = s[7 - i];
	}
	return output;
}

// 右に90度回転
private Stone rotateRight(Stone s) pure {
	byte[8] output;
	for (int i; i < 8; i++) {
		for (int j = 7; j >= 0; j--) {
			output[i] <<= 1;
			if ((s[j] & (0x80 >> i)) != 0) output[i]++;
		}
	}
	return output;
}

// 左に90度回転
private Stone rotateLeft(Stone s) pure {
	byte[8] output;
	for (int i; i < 8; i++) {
		for (int j; j < 8; j++) {
			output[i] <<= 1;
			if ((s[j] & (0x01 << i)) != 0) output[i]++;
		}
	}
	return output;
}

// ビット列を左右反転
private byte bitflip8(byte a) pure {
	int v = a;
	v = ((v & 0b10101010) >> 1) | ((v & 0b01010101) << 1);
	v = ((v & 0b11001100) >> 2) | ((v & 0b00110011) << 2);
	v = (v >> 4) | (v << 4);
	return cast(byte)v;
}
