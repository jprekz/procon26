module charlotte.problemtypes;

class Problem {
    Field field;
    Stone[] stone;
}

struct Stone {
    bool[8][8] _stone;
    alias _stone this;

    Stone inv() {
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

    Field inv() {
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
}
