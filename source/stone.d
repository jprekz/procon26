module stone;

import std.ascii;
import std.format;

struct Stone {
	immutable byte[8] bitArr;

	pure nothrow this(byte[8] bits) {
		bitArr = bits;
	}

	const void toString(scope void delegate(const(char)[]) sink) {
		foreach (b; bitArr) {
			sink(format("%08b", b));
			sink(newline);
		}
	}

	pure bool getbit(int x, int y) {
		return 0 != (bitArr[y] & (0b10000000 >> x));
	}

	pure Stone transform(bool invert, int rotate) {
		assert(rotate >= 0 && rotate < 4);

		if (rotate == 0) {
			return Stone(invert ? bitArr.flip : bitArr);
		} else if (rotate == 1) {
			return Stone(invert ? bitArr.flip.rotateRight : bitArr.rotateRight);
		} else if (rotate == 2) {
			return Stone(invert ? bitArr.reverseStatic : bitArr.reverseStatic.flip);
		} else if (rotate == 3) {
			return Stone(invert ? bitArr.flip.rotateLeft : bitArr.rotateLeft);
		}
		assert(0);
	}
}

private alias map!(a => bitflip8(a)) flip;

private pure byte[8] map(byte function(byte) f)(byte[8] arr) {
	byte[8] output;
	for (int i; i < 8; i++) {
		output[i] = f(arr[i]);
	}
	return output;
}

private pure byte[8] reverseStatic(byte[8] arr) {
	byte[8] output;
	for (int i; i < 8; i++) {
		output[i] = arr[7 - i];
	}
	return output;
}

private pure byte[8] rotateRight(byte[8] arr) {
	byte[8] buf;
	for (int i; i < 8; i++) {
		for (int j = 7; j >= 0; j--) {
			buf[i] <<= 1;
			if ((arr[j] & (0x80 >> i)) != 0) buf[i]++;
		}
	}
	return buf;
}

private pure byte[8] rotateLeft(byte[8] arr) {
	byte[8] buf;
	for (int i; i < 8; i++) {
		for (int j; j < 8; j++) {
			buf[i] <<= 1;
			if ((arr[j] & (0x01 << i)) != 0) buf[i]++;
		}
	}
	return buf;
}

private pure byte bitflip8(byte a) {
	int v = a;
	v = ((v & 0b10101010) >> 1) | ((v & 0b01010101) << 1);
	v = ((v & 0b11001100) >> 2) | ((v & 0b00110011) << 2);
	v = (v >> 4) | (v << 4);
	return cast(byte)v;
}
