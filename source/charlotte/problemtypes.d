module charlotte.problemtypes;

alias Map!(8, 8) Stone;
alias Map!(32, 32) Field;

struct Map(int x, int y) {
    bool[y][x] _map;
    alias _map this;

    typeof(this) inv() const {
        bool[y][x] res;
        for (int i; i < y; i++) {
            for (int j; j < x; j++) {
                res[i][j] = !_map[i][j];
            }
        }
        return typeof(this)(res);
    }

    typeof(this) opBinary(string op)(typeof(this) rhs) {
        static if (op == "&" || op == "|" || op == "^") {
            bool[y][x] l = _map;
            bool[y][x] r = rhs._map;
            bool[y][x] res;
            for (int i; i < y; i++) {
                for (int j; j < x; j++) {
                    res[i][j] = mixin("l[i][j]"~op~"r[i][j]");
                }
            }
            return typeof(this)(res);
        } else {
            static assert(0, "Operator "~op~" not implemented");
        }
    }

    int countEmptyCells() pure {
    	int output;
    	for (int i; i < y; i++) {
    		for (int j; j < x; j++) {
    			if (!_map[i][j]) output++;
    		}
    	}
    	return output;
    }

    typeof(this) bordering() const {
    	bool[y][x] res;
    	for (int i; i < y; i++) {
    		for (int j; j < x; j++) {
    			if (_map[i][j]) continue;
    			if (((i != 0)     && _map[i - 1][j]) ||
    				((j != 0)     && _map[i][j - 1]) ||
    				((j != x - 1) && _map[i][j + 1]) ||
    				((i != y - 1) && _map[i + 1][j])) {
    				res[i][j] = true;
    			}
    		}
    	}
    	return typeof(this)(res);
    }

    string toString() const {
        char[] str;
        foreach (a; _map) {
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

bool isProtrude(Stone stoneRotated, int dx, int dy) pure {
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

Field putStoneOnField(Stone stoneRotated, int dx, int dy) pure {
	Field output;
	for (int y; y < 8; y++) {
		for (int x; x < 8; x++) {
			if (!stoneRotated[y][x]) continue;
			output[y + dy][x + dx] = true;
		}
	}
	return output;
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
