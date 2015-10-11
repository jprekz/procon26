module charlotte.toimpl;

import std.stdio;
import std.conv;

string toImpl16(int num) pure {
    char[] str;
    str ~= c(num / 16);
    str ~= c(num % 16);
    return str.to!string;
}

char c(int n) pure {
    if (n < 10) return (n + '0').to!char;
    else return (n-10 + 'A').to!char;
}
