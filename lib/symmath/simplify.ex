defmodule Symmath.Simplify do
  import Symmath.Guards

  @moduledoc """
  Contains rules to simplify a Symbolic Math expression.
  """
  alias __MODULE__


  @doc """

  ## Examples

  iex> Symmath.expr(3 * (2 * pow(x, 2 - 1)))
  Symmath.expr(6 * x)
  """
  def simplify(expr = %Symmath.Expr{}) do
    %Symmath.Expr{expr | ast: ast_simplify(expr.ast)}
  end

  # Zero-argument base cases

  def ast_simplify(var) when is_var(var) do
    var
  end

  def ast_simplify(constant) when is_constant(constant) do
    constant
  end

  # UNARY

  # Unary operators on computable constants, e.g. -(2) == -2
  @computable_unary_operators [:+, :-]

  def ast_simplify({op, i, [operand]}) when op in @computable_unary_operators and is_number(operand) do
    apply(Kernel, op, [operand])
  end

  # Recursively calling on unary
  def ast_simplify({op, i, [operand]}) do
    {op, i, [ast_simplify(operand)]}
  end

  # BINARY

  # Change (0 + a) to a
  def ast_simplify({:+, _, [0, a]}) do
    a
  end
  
  # Change (a + 0), (a - 0) to a
  def ast_simplify({op, _, [a, 0]}) when op in [:+, :-] do
    a
  end

  # Change (0 - a) to -a
  def ast_simplify({:-, _, [0, a]}) do
    {:-, [], [a]}
  end

  # Change (0 * a) to 0
  def ast_simplify({:*, _, [0, a]}), do: 0
  def ast_simplify({:*, _, [a, 0]}), do: 0


  # Change (1 * a) to a
  def ast_simplify({:*, _, [1, a]}), do: a
  def ast_simplify({:*, _, [a, 1]}), do: a

  # Change (a - a) to 0
  def ast_simplify({:-, _, [a, a]}) do
    0
  end

  # Change (a + a) to (2 * a)
  def ast_simplify({:+, i, [a, a]}) do
    ast_simplify {:*, i, [2, a]}
  end

  # Change (a * a) to pow(a, 2)
  def ast_simplify({:*, i, [a, a]}) do
    ast_simplify {:pow, [], [a, 2]}
  end

  # Change pow(a, 1) to a
  def ast_simplify({:pow, _, [a, 1]}) do
    a
  end

  # Change pow(a, 0) to 1
  def ast_simplify({:pow, _, [a, 0]}) do
    1
  end

  # Operators that are computable when both sides are constants without losing info.
  @computable_binary_operators [:+, :-, :*]

  def ast_simplify({op, i, [lhs, rhs]}) when op in @computable_binary_operators and is_number(lhs) and is_number(rhs) do
    apply(Kernel, op, [lhs, rhs])
  end

  @commutative_operators [:+, :*]

  # Re-order commutative operators to have constants at the front
  # Note that the `<` ensures that we don't continue doing this operation over and over, regardless of if rhs and lhs are numbers or mathematical constants.
  def ast_simplify({op, i, [lhs, rhs]}) when op in @commutative_operators and is_constant(rhs) and rhs < lhs do
    ast_simplify({op, i, [rhs, lhs]})
  end

  # Reduces (3 * (2 * x))  to (6 * x)
  def ast_simplify(expr = {op, i, [lhs, {op2, _, [rhs_a, rhs_b]}]}) 
  when  op in @commutative_operators 
    and op2 == op 
    and is_number(lhs) and is_number(rhs_a)
  do
    new_lhs = apply(Kernel, op, [lhs, rhs_a])
    {op, [], [new_lhs, ast_simplify(rhs_b)]}
  end

  # Commutative Operators: Look two layers deep into right operand, 
  # so things like 2 * (3 * x) are changed to (2 * 3) * x
  def ast_simplify(expr = {op, i, [lhs, {op2, _, [rhs_a, rhs_b]}]}) 
  when  op in @commutative_operators 
    and op2 == op 
    and is_constant(lhs) 
    and is_constant(rhs_a)
    and lhs < rhs_a
  do
    IO.inspect(" #{inspect expr} ## Rebalancing ")
    ast_simplify(  {op, i, [{op, [], [lhs, rhs_a]}, rhs_b]})
  end


  # Change addition with unary minus into minus (2 + (-x)) = (2 - x)
  def ast_simplify({:+, _, [lhs, {:-, _, [rhs]}]}) do
    {:-, [], [lhs, rhs]}
  end

  # Change subtraction with unary minus into plus (2 - (-x)) = (2 - x)
  def ast_simplify({:-, _, [lhs, {:-, _, [rhs]}]}) do
    {:+, [], [lhs, rhs]}
  end

  # Change (2 + (x - 2)) to  x
  def ast_simplify({:+, _, [lhs, {:-, _, [rhs_a, lhs]}]}) do
    rhs_a
  end

  # Change ((2 + x) - 2) to x
  def ast_simplify({:-, _, [{:+, _, [rhs, lhs_b]}, rhs]}) do
    lhs_b
  end  

  # Change (2 - (x - 2)) to -x
  def ast_simplify({:-, _, [lhs, {:-, _, [rhs_a, lhs]}]}) do
    {:-, [], [rhs_a]}
  end 

  # Change ((2 - x) - 2) to -x
  def ast_simplify({:-, _, [{:-, _, [rhs, lhs_b]}, rhs]}) do
    {:-, [], [lhs_b]}
  end

  # Recursively tries simplification on two-argument functions until nothing changes.
  def ast_simplify(original_expr = {op, i, [lhs, rhs]}) do
    new_expr = {op, i, [ast_simplify(lhs), ast_simplify(rhs)]}
    IO.inspect("#{inspect new_expr} ## recursive simplify checking")
    # When simplification happened in one of the operands, maybe we can now simplify the result, so call recursively.
    if new_expr != original_expr do
      ast_simplify(new_expr)
    else
      new_expr
    end
  end

end