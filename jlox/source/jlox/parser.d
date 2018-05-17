module jlox.parser;

import jlox.token;
import jlox.expr, jlox.stmt;

struct Parser
{
    private Token[] _tokens;
    private int _current = 0;

public:
    this(Token[] tokens)
    {
        _tokens = tokens;
    }

    Stmt[] parse()
    {
        Stmt[] statements;

        while (!isAtEnd())
        {
            statements ~= declaration();
        }

        return statements;
    }

private:
    Stmt declaration()
    {
        try
        {
            if (match(TokenType.VAR))
                return varDeclaration();

            return statement();
        }
        catch (ParseException error)
        {
            synchronize();
            return null;
        }
    }

    Stmt statement()
    {
        if (match(TokenType.PRINT))
            return printStatement();

        return expressionStatement();
    }

    Stmt expressionStatement()
    {
        Expr expr = expression();
        consume(TokenType.SEMICOLON, "Expect ';' after expression.");
        return new ExpressionStmt(expr);
    }

    Stmt printStatement()
    {
        Expr value = expression();
        consume(TokenType.SEMICOLON, "Expect ';' after value.");
        return new PrintStmt(value);
    }

    Stmt varDeclaration()
    {
        import std.typecons : Nullable;

        Token name = consume(TokenType.IDENTIFIER, "Expect variable name.");

        Expr initializer;
        if (match(TokenType.EQUAL))
        {
            initializer = expression();
        }

        consume(TokenType.SEMICOLON, "Expect ';' after variable declaration.");
        return new VarStmt(name, Nullable!Expr(initializer));
    }

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
                return new Literal(previous().literal);

            if (match(IDENTIFIER))
                return new Variable(previous());

            if (match(LEFT_PAREN))
            {
                Expr expr = expression();
                consume(RIGHT_PAREN, "Expect ')' after expression.");
                return new Grouping(expr);
            }
        }
        throw error(peek(), "Expect expression.");
    }

    // helper methods

    Token consume(TokenType t, string message)
    {
        if (check(t))
            return advance();
        throw error(peek(), message);
    }

    ParseException error(Token token, string message)
    {
        import jlox.run : error;

        error(token, message);
        return new ParseException(message);
    }

    void synchronize()
    {
        advance();

        while (!isAtEnd())
        {
            with (TokenType)
            {
                if (previous().type == SEMICOLON)
                    return;

                switch (peek().type)
                {
                case CLASS:
                case FUN:
                case VAR:
                case FOR:
                case IF:
                case WHILE:
                case PRINT:
                case RETURN:
                    return;
                default:
                    break;
                }

                advance();
            }
        }
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

private class ParseException : Exception
{
    import std.exception : basicExceptionCtors;

    mixin basicExceptionCtors;
}
