module jlox.stmt;

import std.typecons : Nullable;
import util.codegen;
import jlox.expr, jlox.token;

private enum definition = q"EOS
ExpressionStmt : Expr expression
PrintStmt      : Expr expression
VarStmt        : Token name, Nullable!Expr initializer
EOS";

debug (codegen) pragma(msg, genAst("Stmt", definition));

mixin(genAst("Stmt", definition));
