module jlox.run;

import jlox.token;
import jlox.scanner, jlox.expr;
import jlox.parser;
import jlox.interpreter;

// crappy but this is a small educational interpreter. Surely it won't bite me?
bool hadError;
bool hadRuntimeError;

void error(int line, string message)
{
    report(line, "", message);
}

void error(Token token, string message)
{
    if (token.type == TokenType.EOF)
    {
        report(token.line, " at end", message);
    }
    else
    {
        report(token.line, " at '" ~ token.lexeme ~ "'", message);
    }
}

void report(int line, string where, string message) @trusted
{
    import std.stdio;

    stderr.writefln!"[line %s] Error%s: %s"(line, where, message);
    hadError = true;
}

void runtimeError(RuntimeException e)
{
    import std.stdio;

    stderr.writefln!("%s\n[line %s]")(e.message(), e.token.line);
    hadRuntimeError = true;
}

void runFile(string path) @trusted
{
    import std.file, std.stdio;

    run(cast(string) read(path));
}

void runPrompt() @trusted
{
    import std.stdio, std.string;

    while (true)
    {
        write("> ");
        run(readln().chomp());
        // [BN] if the user makes a mistake, it shouldn’t kill their entire session
        hadError = false;
    }
}

void run(string source)
{
    import std.stdio;
    import ast = jlox.ast_printer;

    auto scanner = Scanner(source);
    Token[] tokens = scanner.scanTokens();
    auto parser = Parser(tokens);
    Expr expression = parser.parse();

    if (hadError)
        return;

    interpret(expression);
}
