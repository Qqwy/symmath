defmodule Symmath.Derivative do
  import Symmath
  import Symmath.Guards

  @doc """
  Attempts to obtain the derivative of a given expression.
  Note that the implementation is probably incomplete.
  """
  def deriv(expr = %Symmath.Expr{}) do
    %Symmath.Expr{expr | ast: ast_deriv(expr.ast)}
  end


  # Derivative of a constant == 0.
  def ast_deriv(a) when is_number(a) do
    0
  end

  # Derivative of an unknown variable
  def ast_deriv(var) when is_var(var) do
    1
  end

  # (a*f())' === (a*f()') Constant Factor Rule
  # def ast_deriv({:*, i, [a, f]}) when is_number(a) do
  #   {:*, i, [a, ast_deriv(f)]}
  # end
  # def ast_deriv({:*, i, [f, a]}) when is_number(a), do: ast_deriv({:*, i, [a, f]})

  # (a+b)' === (a'+b') Sum Rule
  # TODO: Fix.
  def ast_deriv({:+, i, [a, b]}) do
    {:+, i, [ast_deriv(a), ast_deriv(b)]}
  end

  # (a-b)' === (a'-b') Subtraction Rule
  def ast_deriv({:-, i, [a, b]}) do
    {:-, i, [ast_deriv(a), ast_deriv(b)]}
  end

  # (f()*g())' === ((f()'*g()) + (f()*g()')) Product Rule
  def ast_deriv({:*, i, [a, b]}) do
    IO.puts "TEST"
    da = ast_deriv(a)
    db = ast_deriv(b)
    {:+, i, [{:*, [], [da, b]}, {:*, [], [a, db]}]}
  end

  # Derivative of pow(e, x) === pow(e, x) 
  def ast_deriv(ast = {:pow, _, [{:e, _, nil}, exponent] }) do
    ast
  end

  # Derivative of pow(x, r) === r * pow(x, r-1) if r is a real number
  # NOTE: does not use chain rule yet
  def ast_deriv({:pow, i, [base, exponent]}) when is_var(base) and is_constant(exponent) do
    exp_min_one = quote do unquote(exponent) - 1 end
    quote do
      unquote(exponent) * pow(unquote(base), unquote(exp_min_one)) 
    end
  end

end