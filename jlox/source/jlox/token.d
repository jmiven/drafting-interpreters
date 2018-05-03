module jlox.token;
@safe:

import std.variant : Algebraic, visit;

alias Lit = Algebraic!(string, double);

immutable struct Token
{
    import std.typecons : Nullable;

    TokenType type;
    string lexeme;
    Nullable!Lit literal;
    int line;

    this(TokenType _type, string _lexeme, int _line)
    {
        type = _type;
        lexeme = _lexeme;
        line = _line;
    }

    this(TokenType _type, string _lexeme, Lit _literal, int _line)
    {
        type = _type;
        lexeme = _lexeme;
        literal = _literal;
        line = _line;
    }

    string toString() @trusted
    {
        import std.format : format;
        import std.conv : to;

        if (literal.isNull)
            return format!"%s %s"(type, lexeme);

        string lit = literal.get.visit!((string s) => s, (double d) => to!string(d));
        return format!"%s %s %s"(type, lexeme, lit);
    }
}

enum TokenType
{
    // Single-character tokens.
    LEFT_PAREN,
    RIGHT_PAREN,
    LEFT_BRACE,
    RIGHT_BRACE,
    COMMA,
    DOT,
    MINUS,
    PLUS,
    SEMICOLON,
    SLASH,
    STAR,

    // One or two character tokens.
    BANG,
    BANG_EQUAL,
    EQUAL,
    EQUAL_EQUAL,
    GREATER,
    GREATER_EQUAL,
    LESS,
    LESS_EQUAL,

    // Literals.
    IDENTIFIER,
    STRING,
    NUMBER,

    // Keywords.
    AND,
    CLASS,
    ELSE,
    FALSE,
    FUN,
    FOR,
    IF,
    NIL,
    OR,
    PRINT,
    RETURN,
    SUPER,
    THIS,
    TRUE,
    VAR,
    WHILE,

    EOF
}
