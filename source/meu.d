module meu;

import std.stdio;
import std.string;

import field;
import reader;
import stone;
import operate;

class MeuAI {
	const Reader problem;
	void delegate(string[]) findAnswerDelegate;
	const Operate[] allOperateList;

	this(string problemName, void delegate(string[]) findAnswer) {
		problem = new Reader(problemName);
		findAnswerDelegate = findAnswer;
		allOperateList = Operate.calcAllOperateList();
	}

	void start() {
		Stone s = problem.stone[1];
		search(0, problem.field, problem.field.complement, null, true);
	}

	bool search(int stoneNum, Field nowField, Field nowPlaceable, Operate operateList, bool first) {
		if (stoneNum >= problem.stone.length) return end(nowField, operateList);
		foreach (ope; allOperateList) {
			Stone stoneRotated = problem.stone[stoneNum].transform(ope.invert, ope.rotate);
			Field stoneOnField = putStoneOnField(stoneRotated, ope);

			bool result;
			if (ope.passed) {
				result = search(stoneNum + 1,
					nowField,
					nowPlaceable,
					ope.next(operateList),
					first);
			} else {
				if (isProtrude(stoneRotated, ope)) continue;
				if (isOverlap(nowField, stoneOnField)) continue;
				if (!isOverlap(nowPlaceable, stoneOnField)) continue;
				result = search(stoneNum + 1,
					overlap(stoneOnField, nowField),
					(first) ? stoneOnField.bordering : overlap(stoneOnField.bordering, nowPlaceable),
					ope.next(operateList),
					false);
			}
			if (!result) return false;	//resultがfalse(探索を続けない)ならそれを伝搬する
		}
		return true;
	}

	int bestScore = 1024;
	bool end(Field f, Operate operateList) {
		if (bestScore > f.countEmptyCells) {
			bestScore = f.countEmptyCells;
			f.toString.writeln;
			bestScore.writeln;
			writeln("Stopping!");
			writeln("Continue?(y/n)");
			if (readln.chomp != "y") {
				findAnswerDelegate(operateList.getAnswer());
				return false;
			}
		}
		return true;
	}
}

bool isProtrude(Stone stoneRotated, const Operate ope) pure {
	// 右端はみ出し判定
	if (ope.x > 24) {
		foreach (b; stoneRotated) {
			if (b % (2^^(ope.x-24)) != 0) return true;
		}
	}
	// 下端はみ出し判定
	if (ope.y > 24) {
		for (int i = 32 - ope.y; i < 8; i++) {
			if (stoneRotated[i] != 0) return true;
		}
	}
	return false;
}

Field putStoneOnField(Stone stoneRotated, const Operate ope) pure {
	int[32] output;
	int e = (ope.y + 8 < 32) ? ope.y + 8 : 32;
	for (int i = ope.y; i < e; i++) {
		output[i] = stoneRotated[i - ope.y];
		output[i] <<= 24;
		output[i] >>>= ope.x;
	}
	return output;
}
