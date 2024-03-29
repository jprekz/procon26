module app;

import std.stdio;
import std.string;
import std.path;
import std.file;
import std.conv;
import std.array;
import std.algorithm;
import std.datetime;
import std.getopt;
import std.json;
import std.parallelism;
import std.net.curl;
import core.thread;
import std.process;

//import dfs.dfs;
import charlotte.dfs;
import charlotte.mcts;
import charlotte.guarana;

shared string unofficialPracticeHost;
shared string officialPracticeHost;
shared string serverHost;
shared string teamToken;
shared string canonServerHost;
shared string canonToken;

enum Mode { practice, local, direct, canon }

void main(string[] args) {
	int problemNumber = -1;
	int guaranaSkip = 2;
	Mode mode;
	getopt(
		args,
		"num", &problemNumber,
		"guarana|g", &guaranaSkip,
		"mode", &mode
	);

	JSONValue config = parseJSON(read("config.json").to!string);
	unofficialPracticeHost = config["unofficialPracticeHost"].str;
	officialPracticeHost = config["officialPracticeHost"].str;
	serverHost = config["serverHost"].str;
	teamToken = config["teamToken"].str;
	canonServerHost = config["canonServerHost"].str;
	canonToken = config["canonToken"].str;

	string problemFileName = getProblem(mode, problemNumber);
	string problemBaseName = baseName(problemFileName, ".txt");

	void findAnswer(string[] ans, int score, int stones) {
		string answerFileName =
			"./answer/"~problemBaseName~"-"~score.to!string~"-"~stones.to!string~".txt";
		File answerFile = File(answerFileName, "w");
		foreach (string s; ans) {
			answerFile.writeln(s);
		}
		answerFile.close();
		if (mode == Mode.canon) {
			auto curl = execute(["curl", "http://"~canonServerHost~"/answer",
				"--form-string", "score="~score.to!string,
				"--form-string", "stone="~stones.to!string,
				"--form-string", "token="~canonToken,
				"-F", "answer=@"~answerFileName[2 .. $]]);
			curl.output.writeln;
		} else if (mode == Mode.direct) {
			auto curl = execute(["curl", "http://"~serverHost~"/answer",
				"--form-string", "token="~teamToken,
				"-F", "answer=@"~answerFileName[2 .. $]]);
			curl.output.writeln;
			Thread.sleep(dur!("msecs")(800));	//クソ実装
		}
	}
	auto guarana = new Guarana(problemFileName, &findAnswer);
	auto mctsp = new MCTSP!(64)(problemFileName, &findAnswer);
	int bestScore = guarana.start(guaranaSkip);
	mctsp.start(bestScore);
}

string getProblem(Mode mode, ref int problemNumber) {
	string problemFileName;
	if (mode == Mode.practice) {
		int host;
		while (1) {
			writeln("1) unofficial    2) official");
			writeln("select host(1/2): ");
			host = readln.chomp.to!int;
			if (host == 1 || host == 2) break;
		}
		write("input problem num: ");
		problemNumber = readln.chomp.to!int;
		if (host == 1) {
			problemFileName = "./practice/u"~"quest"~problemNumber.to!string~".txt";
			if (!exists(problemFileName)) download(unofficialPracticeHost~"/quest"~problemNumber.to!string~".txt",
				problemFileName);
		} else {
			problemFileName = "./practice/o"~"quest"~problemNumber.to!string~".txt";
			if (!exists(problemFileName)) download(officialPracticeHost~"/"~problemNumber.to!string~".txt",
				problemFileName);
		}
	} else if (mode == Mode.local) {
		write("input file path: ./");
		problemFileName = "./" ~ readln.chomp;
	} else if (mode == Mode.canon) {
		if (problemNumber == -1) {
			write("input problem num: ");
			problemNumber = readln.chomp.to!int;
		}
		problemFileName = "./problem/quest"~problemNumber.to!string~".txt";
		download(canonServerHost~"/quest?num="~problemNumber.to!string,
			problemFileName);
	} else if (mode == Mode.direct) {
		if (problemNumber == -1) {
			write("input problem num: ");
			problemNumber = readln.chomp.to!int;
		}
		problemFileName = "./problem/quest"~problemNumber.to!string~".txt";
		download(serverHost~"/quest"~problemNumber.to!string~".txt?token="~teamToken,
			problemFileName);
	}
	return problemFileName;
}
