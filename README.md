# drafting-interpreters

This is the repository where I keep all the projects I wrote while reading the
excellent [Crafting Interpreters](http://craftinginterpreters.com/) by Bob
Nystrom.

While the interpreters are written in [D](https://dlang.org), I kept the
original names.

## jlox

Mostly straightforward translation from the book. The code was written while I
was a D beginner and the goal was only to practice while reading Part II, so you
shouldn't expect idiomatic code.

### How to build & run

```sh
cd jlox
dub build
./jlox a_lox_source_file # interprets the contents of the file
./jlox # opens an interactive prompt (CTRL-C to quit)
```
### Of note

#### `jlox/expr.d` and `util/codegen.d` (Chapter 5)

Rather than generating the AST types from an external program, I chose to use the
metaprogramming facilities of D, in particular string mixins and CTFE.

It is interesting that the code is basically identical to the one I would have
written for the external generator.

#### `jlox/ast_printer.d` (Chapter 5)

This went through several iterations. I first tried to copy the visitor pattern
from the book, only to find out that in D you can't derive from template
functions (_caveat emptor_, I might be wrong.)

I then reimplemented `Expr` as a `std.variant.Algebraic` alias and used
`std.variant.visit` to implement the printer.

`Algebraic` was satisfying but as it so happens I watched the next day
[Jean-Louis Leroy's presentation at DConf
2018](https://dconf.org/2018/talks/leroy.html) and decided to try his
openmethods instead.

### To Be Continued

This is a work in progress but I'm regularly working through the book.
