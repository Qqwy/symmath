# Symmath

This library is a very, _very_ bare-bones Symbolic Math library for Elixir.

It is mainly a bunch of tests on how macros can rewrite AST right now.

Things that work:

### Creating an Expression

```
iex> require Symmath
iex> Symmath.expr(1+1)
Symmath.expr(1 + 1)
iex> Symmath.expr(3*x+5*pi) 
Symmath.expr(3 * x + 5 * pi) # Note how `x` does not need to be defined, and how `pi` will be used as a mathematical constant.
```

## Taking the Derivative of an Expression

_(This can only recognize a very basic subset of all possible derivatives so far!)_

```
iex> require Symmath
iex> f = Symmath.expr(3*pow(x, 2))
Symmath.expr(3 * pow(x, 2))
iex> Symmath.deriv(f)
Symmath.expr(3 * (2 * pow(x, 2 - 1)))

```

## Simplifying an Expression
 
_(This only does one layer of very basic simplification so far!)_

```
iex> g = Symmath.expr(1+2+3+4))
iex> Symmath.simplify(g)
Symmath.expr(3+3+4)
```

