module jlox.interpreter;

import std.variant;
import openmethods;
import jlox.expr, jlox.stmt, jlox.token;

mixin(registerMethods);

alias Value = Lit;

void interpret(Stmt[] program)
{
    import jlox.run : runtimeError;

    try
    {
        foreach (statement; program)
            execute(statement);
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
    Expr eNumber =
      new Binary(
        new Binary(
          new Literal(Lit(18.0)),
          Token(TokenType.STAR, "*", 1),
          new Literal(Lit(2.0))),
        Token(TokenType.PLUS, "+", 1),
        new Literal(Lit(6.0)));
    Expr eString =
      new Binary(
        new Binary(
          new Literal(Lit("hello")),
          Token(TokenType.PLUS, "+", 1),
          new Literal(Lit(" "))),
        Token(TokenType.PLUS, "+", 1),
        new Literal(Lit("world")));
    Expr eDivByZero =
      new Binary(
        new Literal(Lit(42.0)),
        Token(TokenType.SLASH, "/", 1),
        new Literal(Lit(0.0)));
    Expr eConvertBoolToString =
      new Binary(
        new Literal(Lit("hello")),
        Token(TokenType.PLUS, "+", 1),
        new Literal(Lit(false)));
    Expr eConvertNumberToString =
      new Binary(
        new Literal(Lit("hello")),
        Token(TokenType.PLUS, "+", 1),
        new Literal(Lit(42.0)));
    Expr eConvertNilToString =
      new Binary(
        new Literal(Lit("hello")),
        Token(TokenType.PLUS, "+", 1),
        new Literal(Lit(null)));
    Expr eConvertToStringCommutative =
      new Binary(
        new Literal(Lit(99.0)),
        Token(TokenType.PLUS, "+", 1),
        new Literal(Lit("Luftballons")));
    // dfmt on
    assert(eval(eNumber) == 42.0);
    assert(eval(eString) == "hello world");
    assertThrown!RuntimeException(eval(eDivByZero), "division by zero");
    assert(eval(eConvertBoolToString) == "hellofalse");
    assert(eval(eConvertNumberToString) == "hello42");
    assert(eval(eConvertNilToString) == "hello");
    assert(eval(eConvertToStringCommutative) == "99Luftballons");
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
    import std.conv : to;
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
                tuple(LESS, "<"), tuple(LESS_EQUAL, "<="), tuple(MINUS, "-"), tuple(STAR, "*")])
        {
            mixin(format!tpl_double(t[0], t[1]));
        }
    case SLASH:
        checkNumberOperand(b.operator, left, right);
        if (right == 0.0)
            throw new RuntimeException(b.operator, "division by zero");
        return Value(left.get!double() / right.get!double());
    case BANG_EQUAL:
        return Value(left != right);
    case EQUAL_EQUAL:
        return Value(left == right);
    case PLUS:
        if (bothConvertTo!double(left, right))
            return Value(left.get!double() + right.get!double());
        if (left.convertsTo!string())
            return Value(left.get!string() ~ right.visit!((typeof(null) p) => "", x => to!string(x)));
        if (right.convertsTo!string())
            return Value(left.visit!((typeof(null) p) => "", x => to!string(x)) ~ right.get!string());
        throw new RuntimeException(b.operator,
                "operands must be two numbers or at least one of them must be a string");
    default:
        assert(0, "unreachable");
    }

}

void execute(virtual!Stmt);

@method void _execute(ExpressionStmt stmt)
{
    eval(stmt.expression);
}

@method void _execute(PrintStmt stmt)
{
    import std.stdio : writeln;

    eval(stmt.expression).stringify().writeln();
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
