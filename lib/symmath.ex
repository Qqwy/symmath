defmodule Symmath do
  defmodule Expr do
    defstruct [:ast]
  
    defimpl Inspect do
      def inspect(expr, opts) do
        ast_str = Macro.to_string(expr.ast)
        "Symmath.expr(#{ast_str})"
      end
    end
  end

  @mathematical_constants [:pi, :e, :tau]

  def __using__(opts) do
    quote do
      require Symmath
      import Symmath
      require Symmath.Simplify
      import Symmath.Simplify
    end
  end


  @doc """
  Creates a Symmath Expression.
  `expression` is not immediately evaluated.
  Instead, it is treated as a symbolic representation.
  """
  defmacro expr(expression) do
    escaped_expr = Macro.escape(expression)
    quote do 
        %Expr{ast: unquote(escaped_expr) }
    end
  end


  @doc """
  Attempts to obtain the derivative of a given expression.
  Note that the implementation is probably incomplete.
  """
  def deriv(expr = %Expr{}) do
    %Expr{expr | ast: ast_deriv(expr.ast)}
  end

  @doc """
  Returns 'true' if the passed AST describes a variable.
  The variable itself is not evaluated, nor checked if it exists in the given context.
  """
  defmacro is_var(value)
  defmacro is_var({a, _, ctx}) when is_atom(a) and is_atom(ctx), do: true
  defmacro is_var(_), do: false

  @doc """
  Returns true if the passed value is a constant
  Either a number, or a mathematical constant such as `e` or `pi`.
  """
  defmacro is_constant(value)
  defmacro is_constant(value) when is_number(value), do: true
  defmacro is_constant(value = {name, _, ctx}) when is_var(value) and name in @mathematical_constants, do: true
  defmacro is_constant(_), do: false

  # Derivative of a constant == 0.
  def ast_deriv(a) when is_number(a) do
    0
  end

  # Derivative of an unknown variable
  def ast_deriv(var) when is_var(var) do
    var
  end

  # (a*f())' === (a*f()') Constant Factor Rule
  def ast_deriv({:*, i, [a, f]}) when is_number(a) do
    {:*, i, [a, ast_deriv(f)]}
  end
  def ast_deriv({:*, i, [f, a]}) when is_number(a), do: ast_deriv({:*, i, [a, f]})

  # (a+b)' == (a'+b') Sum Rule
  def ast_deriv({:+, i, [a, b]}) do
    {:+, i, [ast_deriv(a), ast_deriv(b)]}
  end

  # (a-b)' == (a'-b') Subtraction Rule
  def ast_deriv({:-, i, [a, b]}) do
    {:-, i, [ast_deriv(a), ast_deriv(b)]}
  end


  # Derivative of pow(e, x) === pow(e, x) 
  def ast_deriv(ast = {:pow, _, [{:e, _, _}, exponent] }) do
    ast
  end

  # Derivative of pow(x, r) === r * pow(x, r-1) if r is a real number
  def ast_deriv({:pow, i, [base, exponent]}) do
    exp_min_one = quote do unquote(exponent) - 1 end
    quote do
      unquote(exponent) * pow(unquote(base), unquote(exp_min_one)) 
    end
  end
end
