module jlox.scanner;

import jlox.token;
import jlox.run : error;

struct Scanner
{
public:
    this(string source)
    {
        _source = source;
    }

    Token[] scanTokens()
    {
        while (!isAtEnd())
        {
            // [BN] We are at the beginning of the next lexeme
            _start = _current;
            scanToken();
        }

        _tokens ~= Token(TokenType.EOF, "", _line);
        return _tokens;
    }

private:
    immutable string _source;
    Token[] _tokens;
    int _start = 0;
    int _current = 0;
    int _line = 1;

    bool isAtEnd()
    {
        return _current >= _source.length;
    }

    void scanToken()
    {
        char c = advance();
        switch (c) with (TokenType)
        {
        case '(':
            addToken(LEFT_PAREN);
            break;
        case ')':
            addToken(RIGHT_PAREN);
            break;
        case '{':
            addToken(LEFT_BRACE);
            break;
        case '}':
            addToken(RIGHT_BRACE);
            break;
        case ',':
            addToken(COMMA);
            break;
        case '.':
            addToken(DOT);
            break;
        case '-':
            addToken(MINUS);
            break;
        case '+':
            addToken(PLUS);
            break;
        case ';':
            addToken(SEMICOLON);
            break;
        case '*':
            addToken(STAR);
            break;
        case '!':
            addToken(match('=') ? BANG_EQUAL : BANG);
            break;
        case '=':
            addToken(match('=') ? EQUAL_EQUAL : EQUAL);
            break;
        case '<':
            addToken(match('=') ? LESS_EQUAL : LESS);
            break;
        case '>':
            addToken(match('=') ? GREATER_EQUAL : GREATER);
            break;
        case '/':
            if (match('/')) // line comment
            {
                while (peek() != '\n' && !isAtEnd())
                    advance();
            }
            else if (match('*')) // multiline comment
            {
                comment();
            }
            else
            {
                addToken(SLASH);
            }
            break;
        case ' ':
        case '\r':
        case '\t':
            // [BN] Ignore whitespace.
            break;
        case '\n':
            _line++;
            break;
        case '"':
            string_token();
            break;
        default:
            if (isDigit(c))
            {
                number_token();
            }
            else if (isAlpha(c))
            {
                identifier_token();
            }
            else
            {
                error(_line, "Unexpected character");
            }
        }
    }

    // consume _source until the end of comment is found
    void comment()
    {
        while (peek() != '*' && !isAtEnd())
        {
            if (peek() == '\n')
                _line++;
            advance();
        }

        if (isAtEnd())
        {
            error(_line, "Unterminated comment.");
            return;
        }

        advance();
        // we can recurse to look for the terminating '/'
        if (peek() == '/')
        {
            advance();
            return;
        }
        else
        {
            comment();
        }
    }

    void identifier_token()
    {
        while (isAlphaNumeric(peek()))
            advance();

        string id = _source[_start .. _current];
        auto type = id in keywords;
        if (type !is null)
            addToken(*type);
        else
            addToken(TokenType.IDENTIFIER);
    }

    void string_token()
    {
        while (peek() != '"' && !isAtEnd())
        {
            // multiline strings are supported so we need to update line
            // when we hit a newline inside a string
            if (peek() == '\n')
                _line++;
            advance();
        }

        // [BN] Unterminated string.
        if (isAtEnd())
        {
            error(_line, "Unterminated string.");
            return;
        }

        // [BN] The closing ".
        advance();

        // [BN] Trim the surrounding quotes.
        string value = _source[_start + 1 .. _current - 1];
        addToken(TokenType.STRING, Lit(value));
    }

    bool isDigit(char c)
    {
        return c >= '0' && c <= '9';
    }

    bool isAlpha(char c)
    {
        return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_';
    }

    bool isAlphaNumeric(char c)
    {
        return isAlpha(c) || isDigit(c);
    }

    void number_token()
    {
        import std.conv : to;

        while (isDigit(peek()))
            advance();

        // Look for a fractional part.
        if (peek() == '.' && isDigit(peekNext()))
        {
            // Consume the "."
            advance();

            while (isDigit(peek()))
                advance();
        }

        auto num = to!double(_source[_start .. _current]);
        addToken(TokenType.NUMBER, Lit(num));
    }

    char peekNext()
    {
        if (_current + 1 >= _source.length)
            return '\0';
        return _source[_current + 1];
    }

    bool match(char expected)
    {
        if (isAtEnd())
            return false;
        if (_source[_current] != expected)
            return false;
        _current++;
        return true;
    }

    char peek()
    {
        if (isAtEnd())
            return '\0';
        return _source[_current];
    }

    char advance()
    {
        _current++;
        return _source[_current - 1];
    }

    void addToken(TokenType type)
    {
        string text = _source[_start .. _current];
        _tokens ~= Token(type, text, _line);
    }

    void addToken(TokenType type, Lit literal)
    {
        string text = _source[_start .. _current];
        _tokens ~= Token(type, text, literal, _line);
    }
}

private immutable TokenType[string] keywords;

static this()
{
    with (TokenType)
    {
        keywords["and"] = AND;
        keywords["class"] = CLASS;
        keywords["else"] = ELSE;
        keywords["false"] = FALSE;
        keywords["for"] = FOR;
        keywords["fun"] = FUN;
        keywords["if"] = IF;
        keywords["nil"] = NIL;
        keywords["or"] = OR;
        keywords["print"] = PRINT;
        keywords["return"] = RETURN;
        keywords["super"] = SUPER;
        keywords["this"] = THIS;
        keywords["true"] = TRUE;
        keywords["var"] = VAR;
        keywords["while"] = WHILE;
    }
}
