module jlox.run;

// crappy but this is a small educational interpreter. Surely it won't bite me?
bool hadError;

void error(int line, string message)
{
    report(line, "", message);
}

void report(int line, string where, string message) @trusted
{
    import std.stdio;

    stderr.writefln("[line %s] Error%s: %s", line, where, message);
    hadError = true;
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
    import jlox.scanner, jlox.token;

    auto scanner = Scanner(source);
    Token[] tokens = scanner.scanTokens();

    foreach (tok; tokens)
    {
        writeln(tok);
    }
}
