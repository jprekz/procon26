module charlotte.problemtypes;

class Problem {
    Field field;
    Stone[] stone;
}

struct Stone {
    bool[8][8] _stone;
    alias _stone this;
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
    Stone s = [
        [1,0,0,1,1,0,0,0],
        [1,0,0,1,1,0,0,0],
        [1,1,1,1,1,0,0,0],
        [0,0,0,1,1,0,0,0],
        [0,0,0,1,1,0,0,0],
        [0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0]
    ];
    assert(s[1][0] == true);
}
