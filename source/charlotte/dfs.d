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
	const void delegate(string[]) findAnswerDelegate;
    const Place[] allPlaceList = calcAllPlaceList;

	this(string problemName, void delegate(string[]) findAnswer) {
		problem = new Reader(problemName);
		findAnswerDelegate = findAnswer;
	}

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

	void start() {
		search( new Node(
			0,
			problem.field,
			problem.field.inv,
			true,
			null
		));
	}

	Node[] nodeStack;
	void search(Node firstNode) {
		nodeStack ~= firstNode;
		const int stonesTotal = problem.stone.length;

		while (nodeStack.length != 0) {
			Node now = nodeStack.back;
			nodeStack.popBack();

			if (now.depth >= stonesTotal) {
				end(now.nowField, now.searchingAnswer);
				continue;
			}

			// パス
			nodeStack ~= new Node(
				now.depth + 1,
				now.nowField,
				now.placeableMap,
				now.first,
				new Operation(now.searchingAnswer)
			);

			foreach (Place p; allPlaceList) {
				// 石を回転
				Stone stoneRotated = problem.stone[now.depth].transform(p.flip, p.rotate);

				// 石がフィールド外にはみ出さないか
				if (stoneRotated.isProtrude(p.x, p.y)) continue;

				// 石をField座標に配置
				Field placedStone = stoneRotated.putStoneOnField(p.x, p.y);

				// 石が置ける位置にあるか
				if ((placedStone & now.nowField) != Field.init ||
					(placedStone & now.placeableMap) == Field.init) {
					continue;
				}

				nodeStack ~= new Node(
					now.depth + 1,
					now.nowField | placedStone,
					(now.first) ? placedStone.bordering
						: (now.placeableMap | placedStone.bordering),
					false,
					new Operation(p, now.searchingAnswer)
				);
			}
		}
	}

	int bestScore = 1024;
	void end(Field f, Operation ans) {
		if (bestScore <= f.countEmptyCells) return;
		bestScore = f.countEmptyCells;
		f.toString.writeln;
		bestScore.writeln;
		findAnswerDelegate(ans.getAnswer());
	}
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
	ls.reverse();
    return ls;
}
