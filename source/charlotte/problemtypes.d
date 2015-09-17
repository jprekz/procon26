module charlotte.problemtypes;

struct Stone {
    bool[8][8] _stone;
    alias _stone this;

    Stone inv() const {
        bool[8][8] res;
        for (int i; i < 8; i++) {
            for (int j; j < 8; j++) {
                res[i][j] = !_stone[i][j];
            }
        }
        return Stone(res);
    }

    Stone opBinary(string op)(Stone rhs) {
        static if (op == "&" || op == "|" || op == "^") {
            bool[8][8] l = _stone;
            bool[8][8] r = rhs._stone;
            bool[8][8] res;
            for (int i; i < 8; i++) {
                for (int j; j < 8; j++) {
                    res[i][j] = mixin("l[i][j]"~op~"r[i][j]");
                }
            }
            return Stone(res);
        } else {
            static assert(0, "Operator "~op~" not implemented");
        }
    }

    string toString() const {
        char[] str;
        foreach (a; _stone) {
            foreach (b; a) {
                str ~= (b) ? '#' : '-';
            }
            str ~= '\n';
        }
        return str.idup;
    }
}

struct Field {
    bool[32][32] _field;
    alias _field this;

    Field inv() const {
        bool[32][32] res;
        for (int i; i < 32; i++) {
            for (int j; j < 32; j++) {
                res[i][j] = !_field[i][j];
            }
        }
        return Field(res);
    }

    Field opBinary(string op)(Field rhs) {
        static if (op == "&" || op == "|" || op == "^") {
            bool[32][32] l = _field;
            bool[32][32] r = rhs._field;
            bool[32][32] res;
            for (int i; i < 32; i++) {
                for (int j; j < 32; j++) {
                    res[i][j] = mixin("l[i][j]"~op~"r[i][j]");
                }
            }
            return Field(res);
        } else {
            static assert(0, "Operator "~op~" not implemented");
        }
    }

    int countEmptyCells() pure {
    	int output;
    	for (int x; x < 32; x++) {
    		for (int y; y < 32; y++) {
    			if (!_field[y][x]) output++;
    		}
    	}
    	return output;
    }

    string toString() const {
        char[] str;
        foreach (a; _field) {
            foreach (b; a) {
                str ~= (b) ? '#' : '-';
            }
            str ~= '\n';
        }
        return str.idup;
    }
}

// invert ... 反転するか否か
// rotate(0 ~ 3) ... 引数 * 90度 右に回転
Stone transform(Stone s, bool invert, int rotate) pure {
	assert(rotate >= 0 && rotate < 4);

    Stone stMap(string str)() {
	    bool[8][8] output;
    	for (int a; a < 8; a++) {
    		for (int b; b < 8; b++) {
                mixin(str);
    		}
    	}
        return Stone(output);
    }

	if (rotate == 0) {
        if (!invert) {
            return stMap!("output[a][b] = s[a][b];");
        } else {
            return stMap!("output[a][7-b] = s[a][b];");
        }
	} else if (rotate == 1) {
        if (!invert) {
            return stMap!("output[b][7-a] = s[a][b];");
        } else {
            return stMap!("output[7-b][7-a] = s[a][b];");
        }
	} else if (rotate == 2) {
        if (!invert) {
            return stMap!("output[7-a][7-b] = s[a][b];");
        } else {
            return stMap!("output[7-a][b] = s[a][b];");
        }
	} else if (rotate == 3) {
        if (!invert) {
            return stMap!("output[7-b][a] = s[a][b];");
        } else {
            return stMap!("output[b][a] = s[a][b];");
        }
	}
    assert(0);
}



unittest {
    assert(Stone.sizeof == 64);
    assert(Field.sizeof == 1024);
    Stone s = Stone([
        [1,0,0,1,1,0,0,0],
        [1,0,0,1,1,0,0,0],
        [1,1,1,1,1,0,0,0],
        [0,0,0,1,1,0,0,0],
        [0,0,0,1,1,0,0,0],
        [0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0]
    ]);
    assert(s[1][0] == true);
    assert(s.inv.inv == s);
    assert((s & s) == s);
    assert(s.transform(false, 0) == s);
    assert(s.transform(true, 0).transform(true, 0) == s);
    assert(s.transform(false, 1).transform(false, 3) == s);
}
