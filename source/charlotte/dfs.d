module charlotte.dfs;

import std.stdio;
import std.string;
import std.range;
import std.algorithm;
import std.typecons;
import std.traits :EnumMembers;

import charlotte.answertypes;
import charlotte.problemreader;
import charlotte.problemtypes;

class DFS {
	const Reader problem;
	void delegate(string[]) findAnswerDelegate;
    const Place[] allPlaceList = calcAllPlaceList;

	class Node {
	    int depth;
	    Field nowField;
	    Field placeableMap;
	    bool first;
	    Operation searchingAnswer;
		this(int d, Field n, Field p, bool f, Operation s) {
			depth = d; nowField = n; placeableMap = p;
			first = f; searchingAnswer = s;
		}
	}

	this(string problemName, void delegate(string[]) findAnswer) {
		problem = new Reader(problemName);
		findAnswerDelegate = findAnswer;
	}

	void start() {
		search( new Node(
			0,
			problem.field,
			problem.field.inv,
			true,
			null
		));
	}

	bool search(Node now) {
		if (now.depth >= problem.stone.length) {
			now.nowField.writeln;
			now.searchingAnswer.writeln;
			return false;
		}
		now.depth.writeln();
		foreach (Place p; allPlaceList) {
			// 石を回転
			Stone stoneRotated = problem.stone[now.depth].transform(p.flip, p.rotate);

			// 石がフィールド外にはみ出さないか
			if (stoneRotated.isProtrude(p.x, p.y)) continue;

			// 石をField座標に配置
			Field placedStone = stoneRotated.putStoneOnField(p.x, p.y);

			// 石がおける位置にあるか
			if ((placedStone & now.nowField) != Field.init ||
				(placedStone & now.placeableMap) == Field.init) {
				continue;
			}

			search( new Node(
				now.depth + 1,
				now.nowField | placedStone,
				now.placeableMap | placedStone.bordering,
				false,
				new Operation(p, now.searchingAnswer)
			));
		}

		search(new Node(
			now.depth + 1,
			now.nowField,
			now.placeableMap,
			now.first,
			new Operation(now.searchingAnswer)
		));

		return false;
	}
}

Field bordering(ref const Field f) {
	Field output;
	for (int x; x < 32; x++) {
		for (int y; y < 32; y++) {
			if (f[y][x]) continue;
			if (((y != 0) && f[y-1][x]) ||
				((x != 0) && f[y][x-1]) ||
				((x != 31) && f[y][x+1]) ||
				((y != 31) && f[y+1][x])) {
				output[y][x] = true;
			}
		}
	}
	return output;
}

bool isProtrude(Stone stoneRotated, int dx, int dy) {
	for (int y; y < 8; y++) {
		for (int x; x < 8; x++) {
			if (!stoneRotated[y][x]) continue;
			int absx = x + dx, absy = y + dy;
			if (absx < 0 || absx > 31 || absy < 0 || absy > 31) {
				return true;
			}
		}
	}
	return false;
}

Field putStoneOnField(Stone stoneRotated, int dx, int dy) {
	Field output;
	for (int y; y < 8; y++) {
		for (int x; x < 8; x++) {
			if (!stoneRotated[y][x]) continue;
			output[y + dy][x + dx] = true;
		}
	}
	return output;
}

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
    return ls;
}