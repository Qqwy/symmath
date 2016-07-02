defmodule Symmath.Simplify do
  import Symmath.Guards

  @moduledoc """
  Contains rules to simplify a Symbolic Math expression.
  """
  alias __MODULE__
  import Symmath

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

  for op <- @computable_binary_operators do
    def ast_simplify({op, i, [lhs, rhs]}) when is_constant(lhs) and is_constant(rhs) do
      apply(Kernel, op, [lhs, rhs])
    end
  end

  def ast_simplify({op, i, [lhs, rhs]}) do
    {op, i, [ast_simplify(lhs), ast_simplify(rhs)]}
  end

end