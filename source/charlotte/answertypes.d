module charlotte.answertypes;

class Operation {
    Place place;
    bool passed;
    Operation before;

    this(Place p, Operation o) {
        place = p;
        passed = false;
        before = o;
    }

    this(Operation o) {
        passed = true;
        before = o;
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
}
