defmodule Symmath.Derivative do
  import Symmath
  import Symmath.Guards

  @doc """
  Attempts to obtain the derivative of a given expression.
  Note that the implementation is probably incomplete.
  """
  def deriv(expr = %Symmath.Expr{}) do
    expr
    |> simplify
    |> do_deriv
    |> simplify    
  end

  defp do_deriv(expr = %Symmath.Expr{}) do
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

  # pow(f(x), r) -> in this case, apply chain rule to inside.
  def ast_deriv(expr = {:pow, i, [base, exponent]}) when is_constant(exponent) do
    apply_chain_rule(expr, base)
  end

  def ast_deriv(expr = {:pow, i, [base, exponent]}) when not(is_constant(exponent)) and not(is_var(exponent)) do
    apply_chain_rule(expr, exponent)
  end

  # For any unmatched operation, try the chain rule.
  def ast_deriv(expr = {op, i, [lhs, rhs]}) do
    #apply_chain_rule(expr, rhs)
    expr
  end

  # TODO: Buggy implementation. Will go wrong if :x is also part of other operand of `outer`.
  def apply_chain_rule(outer, inner) do
    # 1. Rewrite 'inner' in outer as var(x)
    # 2. derive `outer`
    # 3. Rewrite var(x) back as `inner` in the result.
    outer_deriv = 
      outer
      |> rewrite_expr_as_x(inner)
      |> ast_deriv
      |> rewrite_x_as_expr(inner)

    {:* ,[], [outer_deriv, ast_deriv(inner)]}
  end

  def rewrite_expr_as_x(containing_expr, expr) do
    containing_expr |> Macro.prewalk(fn cur_expr -> 
      case cur_expr do
        expr          -> Macro.var(:x, nil)
        {:x, [], nil} -> {:_x, [], nil}
      _               -> cur_expr
      end
    end)
  end

  def rewrite_x_as_expr(containing_expr, expr) do
    containing_expr |> Macro.postwalk(fn cur_expr -> 
      case cur_expr do
        {:x,  [], nil} -> expr
        {:_x, [], nil} -> {:x, [], nil}
        _              -> cur_expr
      end
    end)
  end




end