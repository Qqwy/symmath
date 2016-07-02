defmodule Symmath.Simplify do
  import Symmath.Guards

  @moduledoc """
  Contains rules to simplify a Symbolic Math expression.
  """
  alias __MODULE__

  def simplify(expr = %Symmath.Expr{}) do
    %Symmath.Expr{expr | ast: ast_simplify(expr.ast)}
  end

  def ast_simplify(var) when is_var(var) do
    var
  end

  def ast_simplify(constant) when is_constant(constant) do
    constant
  end

  # Operators that are computable when both sides are constants without losing info.
  @computable_binary_operators [:+, :-, :*]

  def ast_simplify({op, i, [lhs, rhs]}) when op in [:+, :-, :*] and is_constant(lhs) and is_constant(rhs) do
    apply(Kernel, op, [lhs, rhs])
  end

  # Re-order commutative operators to have constants at the front
  def ast_simplify({op, i, [lhs, rhs]}) when op in [:+, :*] and is_constant(rhs) do
    ast_simplify({op, i, [rhs, lhs]})
  end

  # Commutative Operators: Look two layers deep into right operand, 
  # so things like 2 * (3 * x) are changed to (2 * 3) * x
  def ast_simplify({op, i, [lhs, {op2, _, [rhs_a, rhs_b]}]}) when op in [:+, :*] and op2 == op and is_constant(lhs) and is_constant(rhs_a) do
    ast_simplify(  {op, i, [{op, [], [lhs, rhs_a]}, rhs_b]})
  end



  def ast_simplify(original_expr = {op, i, [lhs, rhs]}) do
    new_expr = {op, i, [ast_simplify(lhs), ast_simplify(rhs)]}
    
    # When simplification happened in one of the operands, maybe we can now simplify the result, so call recursively.
    if new_expr != original_expr do
      ast_simplify(new_expr)
    else
      new_expr
    end
  end

end