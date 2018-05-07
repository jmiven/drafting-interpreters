module jlox.interpreter;

import std.variant;
import openmethods;
import jlox.expr, jlox.token;

mixin(registerMethods);

alias Value = Lit;

void interpret(Expr expression)
{
    import jlox.run : runtimeError;
    import std.stdio : writeln;

    try
    {
        Value v = eval(expression);
        writeln(stringify(v));

    }
    catch (RuntimeException e)
    {
        runtimeError(e);
    }
}

private string stringify(Value v)
{
    import std.conv : to;
    import std.variant : visit;

    return v.visit!((typeof(null) p) => "nil", x => to!string(x));
}

unittest
{
    assert(Value(12.0).stringify() == "12");
    assert(Value(false).stringify() == "false");
    assert(Value(true).stringify() == "true");
    assert(Value(null).stringify() == "nil");
}

Value eval(virtual!Expr);

unittest
{
    import std.exception : assertThrown;

    // dfmt off
    Expr e1 =
      new Binary(
        new Binary(
          new Literal(Lit(18.0)),
          Token(TokenType.STAR, "*", 1),
          new Literal(Lit(2.0))),
        Token(TokenType.PLUS, "+", 1),
        new Literal(Lit(6.0)));
    Expr e2 =
      new Binary(
        new Binary(
          new Literal(Lit("hello")),
          Token(TokenType.PLUS, "+", 1),
          new Literal(Lit(" "))),
        Token(TokenType.PLUS, "+", 1),
        new Literal(Lit("world")));
    Expr e3 =
      new Binary(
        new Literal(Lit("hello")),
        Token(TokenType.PLUS, "+", 1),
        new Literal(Lit(false)));
    // dfmt on
    assert(eval(e1) == 42.0);
    assert(eval(e2) == "hello world");
    assertThrown!RuntimeException(eval(e3));
}

@method Value _eval(Literal l)
{
    return l.value;
}

@method Value _eval(Grouping g)
{
    return eval(g.expression);
}

@method Value _eval(Unary u)
{
    Value right = eval(u.right);

    switch (u.operator.type) with (TokenType)
    {
    case BANG:
        return Value(!isTruthy(right));
    case MINUS:
        checkNumberOperand(u.operator, right);
        return Value(-right.get!double());
    default:
        assert(0, "unreachable");
    }
}

@method Value _eval(Binary b)
{
    import std.typecons : tuple;
    import std.format : format;

    Value left = eval(b.left);
    Value right = eval(b.right);

    switch (b.operator.type) with (TokenType)
    {
        enum tpl_double = q{
          case %s:
            checkNumberOperand(b.operator, left, right);
            return Value(left.get!double() %s right.get!double());
        };
        static foreach (t; [tuple(GREATER, ">"), tuple(GREATER_EQUAL, ">="),
                tuple(LESS, "<"), tuple(LESS_EQUAL, "<="), tuple(MINUS, "-"),
                tuple(SLASH, "/"), tuple(STAR, "*")])
        {
            mixin(format!tpl_double(t[0], t[1]));
        }

    case BANG_EQUAL:
        return Value(left != right);
    case EQUAL_EQUAL:
        return Value(left == right);
    case PLUS:
        if (bothConvertTo!double(left, right))
            return Value(left.get!double() + right.get!double());
        if (bothConvertTo!string(left, right))
            return Value(left.get!string() ~ right.get!string());
        throw new RuntimeException(b.operator, "operands must be two numbers or two strings");
    default:
        assert(0, "unreachable");
    }

}

class RuntimeException : Exception
{
    immutable Token token;

    this(Token token, string msg)
    {
        super(msg);
        this.token = token;
    }
}

private:

alias bothConvertTo(T) = (l, r) => l.convertsTo!T() && r.convertsTo!T();

bool isTruthy(Value v)
{
    return v.visit!((typeof(null) p) => false, (bool b) => b, other => true);
}

void checkNumberOperand(Token operator, Value operand)
{
    if (operand.convertsTo!double)
        return;
    throw new RuntimeException(operator, "operand must be a number");
}

void checkNumberOperand(Token operator, Value left, Value right)
{
    if (bothConvertTo!double(left, right))
        return;
    throw new RuntimeException(operator, "operands must be numbers");
}
