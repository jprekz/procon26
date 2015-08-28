module charlotte.problemtypes;

struct Problem {
    Field field;
    Stone[] stones;
}

alias bool[8][8] Stone;

alias bool[32][32] Field;

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
