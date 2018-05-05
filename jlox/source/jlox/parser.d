module jlox.parser;

import jlox.token;
import jlox.expr;

struct Parser
{
public:
    this(Token[] tokens)
    {
        _tokens = tokens;
    }

private:
    Token[] _tokens;
    int _current = 0;

    Expr expression()
    {
        return equality();
    }

    Expr equality()
    {
        with (TokenType)
            return leftAssocBinary(&comparison, BANG_EQUAL, EQUAL_EQUAL);
    }

    Expr comparison()
    {
        with (TokenType)
            return leftAssocBinary(&addition, GREATER, GREATER_EQUAL, LESS, LESS_EQUAL);
    }

    Expr addition()
    {
        with (TokenType)
            return leftAssocBinary(&multiplication, MINUS, PLUS);
    }

    Expr multiplication()
    {
        with (TokenType)
            return leftAssocBinary(&unary, SLASH, STAR);
    }

    Expr unary()
    {
        if (match(TokenType.BANG, TokenType.MINUS))
        {
            Token operator = previous();
            Expr right = unary();
            return new Unary(operator, right);
        }

        return primary();
    }

    Expr primary()
    {
        with (TokenType)
        {
            if (match(FALSE))
                return new Literal(Lit(false));
            if (match(TRUE))
                return new Literal(Lit(true));
            if (match(NIL))
                return new Literal(Lit(null));

            if (match(NUMBER, STRING))
            {
                return new Literal(previous().literal);
            }

            if (match(LEFT_PAREN))
            {
                Expr expr = expression();
                consume(RIGHT_PAREN, "Expect ')' after expression.");
                return new Grouping(expr);
            }
        }
        assert(0); // unreachable
    }

    // helper methods

    void consume(TokenType t, string s)
    {
        // stub
    }

    Expr leftAssocBinary(Expr delegate() rule, TokenType[] operators...)
    {
        Expr expr = rule();
        while (match(operators))
        {
            Token operator = previous();
            Expr right = rule();
            expr = new Binary(expr, operator, right);
        }
        return expr;
    }

    bool match(TokenType[] types...)
    {
        foreach (t; types)
        {
            if (check(t))
            {
                advance();
                return true;
            }
        }

        return false;
    }

    bool check(TokenType tokenType)
    {
        if (isAtEnd())
            return false;
        return peek().type == tokenType;
    }

    Token advance()
    {
        if (!isAtEnd())
            _current++;
        return previous();
    }

    bool isAtEnd()
    {
        return peek().type == TokenType.EOF;
    }

    Token peek()
    {
        return _tokens[_current];
    }

    Token previous()
    {
        return _tokens[_current - 1];
    }
}
