module util.codegen;

import std.algorithm.iteration : joiner;
import std.format : format;

string genAst(string baseName, string typesDefinition)
{
    string[][string] fieldsOfType = parseDef(typesDefinition);

    string types;
    foreach (t, fs; fieldsOfType)
    {
        types ~= genType(t, baseName, fs);
    }

    enum tpl = q{
      class %s {}

      %s
    };
    return format!tpl(baseName, types);
}

private string genType(string typeName, string baseName, string[] fields)
{
    string fieldsInitialization(string[] fields)
    {
        import std.array : split;

        string res;
        foreach (f; fields)
        {
            string fieldname = f.split[1];
            res ~= format!"this.%s = %s;\n"(fieldname, fieldname);
        }
        return res;
    }

    enum tpl = q{
      class %s : %s {
        %s;

        this(%s)
        {
          %s
        }
      }
    };
    return format!tpl(typeName, baseName, fields.joiner(";\n"),
            fields.joiner(", "), fieldsInitialization(fields));
}

private string[][string] parseDef(string typesDefinition)
{
    import std.array : split;
    import std.algorithm.iteration : map;
    import std.string : lineSplitter, strip;

    string[][string] res;
    foreach (type; typesDefinition.lineSplitter)
    {
        auto parts = type.split(":").map!(strip);
        auto fields = parts[1].split(", ");
        res[parts[0]] = fields;
    }

    return res;
}
