module jlox.ast_printer;

import jlox.expr;
import openmethods;

mixin(registerMethods);

string show(virtual!Expr);

@method string _show(Binary b)
{
    return parenthesize(b.operator.lexeme, b.left, b.right);
}

@method string _show(Grouping g)
{
    return parenthesize("group", g.expression);
}

@method string _show(Literal l)
{
    import std.variant : visit;
    import std.conv : to;

    return l.value.visit!((string s) => s, (double d) => to!string(d));
}

@method string _show(Unary u)
{
    return parenthesize(u.operator.lexeme, u.right);
}

private string parenthesize(string name, Expr[] exprs...)
{
    import std.format : format;

    string res = format!"(%s"(name);
    foreach (e; exprs)
    {
        res ~= format!" %s"(show(e));
    }
    res ~= ")";

    return res;
}

unittest
{
    updateMethods();
    import jlox.token;

    // dfmt off
    Expr e1 =
      new Binary(
        new Unary(
               Token(TokenType.MINUS, "-", 1),
               new Literal(Lit(42.0))),
        Token(TokenType.STAR, "*", 1),
        new Grouping(
               new Binary(
                      new Literal(Lit(12.0)),
                      Token(TokenType.PLUS, "+", 1),
                      new Literal(Lit(90.0)))));
    // dfmt on

    assert(show(e1) == "(* (- 42) (group (+ 12 90)))");
}
