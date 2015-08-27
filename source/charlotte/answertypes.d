module charlotte.answertypes;

import std.variant;

alias Operation[] Answer;

struct Operation {
    struct Pass {}
    static pass = Pass();

    Algebraic!(Place, Pass) _operation;
    alias _operation this;

    this(T)(T init) {
        _operation = init;
    }
}

struct Place {
    bool flip;
    Rotation rotate;
    int x;
    int y;
}

enum Rotation {
    deg0, deg90, deg180, deg270
}

unittest {
    auto p = Place(true, Rotation.deg0, 1, 2);
    Operation a = Operation.pass;
    Operation b = p;
    assert(a == Operation.pass);
    Operation[2] opes;
    Answer ans = opes;
}
