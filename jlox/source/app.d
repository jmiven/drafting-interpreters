int main(string[] args)
{
    import std.stdio : writeln;
    import jlox.run : runFile, runPrompt, hadError;
    static import openmethods;

    openmethods.updateMethods();

    if (args.length > 2)
    {
        writeln("usage: jlox [script]");
    }
    else if (args.length == 2)
    {
        runFile(args[1]);
    }
    else
    {
        runPrompt();
    }

    if (hadError)
        return (65);
    return (0);
}
