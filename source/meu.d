module meu;

import std.stdio;

import field;
import reader;
import stone;

class MeuAI {
	const Reader problem;

	this(string fileName) {
		problem = new Reader(fileName);
	}

	void start() {
		auto s = problem.stone[1];
		writeln(problem.field.toString);
		writeln(s.toString);
		writeln(s.transform(true, 0).toString);
		writeln(s.transform(true, 1).toString);
		writeln(s.transform(true, 2).toString);
		writeln(s.transform(true, 3).toString);

		// search(0, problem.field, problem.field.complement, null);
	}

	void search(int stoneNum, Field nowField, Field nowPlaceable, Operate operateList) {
		if (stoneNum >= problem.stone.length) return end(operateList);

	}


	void end(Operate operateList) {

	}
}

class Operate {
	public:
	bool passed;
	int x;
	int y;
	bool invert;
	int rotate;
	Operate before;
}
