module jlox.expr;

import jlox.token;
import util.codegen : genAst;

private enum definition = q"EOS
Binary   : Expr left, Token operator, Expr right
Grouping : Expr expression
Literal  : Lit value
Unary    : Token operator, Expr right
Variable : Token name
EOS";

// run with `dub build -d=codegen` to print the generated code
debug (codegen) pragma(msg, genAst("Expr", definition));

mixin(genAst("Expr", definition));
