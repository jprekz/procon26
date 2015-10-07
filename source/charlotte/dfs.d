module charlotte.dfs;

import std.stdio;
import std.range;
import std.algorithm;
import std.typecons;
import std.parallelism;
import std.datetime;
import std.conv;

import charlotte.answertypes;
import charlotte.problemreader;
import charlotte.problemtypes;
import charlotte.problemanalyzer;

class DFS {
	const Problem problem;
    const void delegate(string[], int) findAnswerDelegate;
    const Analyzer analyzed;
	StopWatch sw;

	this(string problemName, void delegate(string[], int) findAnswer) {
		problem = problemRead(problemName);
		findAnswerDelegate = findAnswer;
        analyzed = new Analyzer(problem).calcStone;
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
		sw.start();
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
		const int stonesTotal = problem.stone.length.to!int;

		while (nodeStack.length != 0) {
			Node now = nodeStack.back;
			nodeStack.popBack();
			//writeln(nodeStack.length, " ", now.depth);

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

			Node[allPlaceList.length] results;
			foreach (i, p; parallel(allPlaceList)) {
            	if (analyzed.stone[now.depth].isSkip(p)) continue;

				// 石を回転
				Stone stoneRotated = problem.stone[now.depth].transform(p.flip, p.rotate);

				// 石がフィールド外にはみ出さないか
				if (stoneRotated.isProtrude(p.x, p.y)) continue;

				// 石をField座標に配置
				Field placedStone = stoneRotated.putStoneOnField(p.x, p.y);

				// 石が置ける位置にあるか
				if ((placedStone.isWrap(now.nowField)) ||
					!(placedStone.isWrap(now.placeableMap))) {
					continue;
				}

				results[i] = new Node(
					now.depth + 1,
					now.nowField | placedStone,
					(now.first) ? placedStone.bordering
						: (now.placeableMap | placedStone.bordering),
					false,
					new Operation(p, now.searchingAnswer)
				);
			}
			foreach (result; results) {
				if (!(result is null)) nodeStack ~= result;
			}
		}
	}

	int bestScore = 1024;
	void end(Field f, Operation ans) {
        int score = f.countEmptyCells;
        if (bestScore <= score) return;
        bestScore = score;
        writeln(f.toString, score);
        findAnswerDelegate(ans.getAnswer(), score);
	}
}
