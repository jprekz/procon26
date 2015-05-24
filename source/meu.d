module meu;

import std.stdio;

import field;
import reader;
import stone;

Reader problem;

void start(string fileName) {
	problem = new Reader(fileName);
	auto s = problem.stone[1];
	writeln(problem.field.toString);
	writeln(s.toString);
	writeln(s.transform(true, 0).toString);
	writeln(s.transform(true, 1).toString);
	writeln(s.transform(true, 2).toString);
	writeln(s.transform(true, 3).toString);
}
