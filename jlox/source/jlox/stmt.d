module jlox.stmt;

import util.codegen;
import jlox.expr;

private enum definition = q"EOS
ExpressionStmt : Expr expression
PrintStmt      : Expr expression
EOS";

debug (codegen) pragma(msg, genAst("Stmt", definition));

mixin(genAst("Stmt", definition));
