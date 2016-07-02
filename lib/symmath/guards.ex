defmodule Symmath.Guards do
  @moduledoc """
  Defines common guard expressions
  """

  @doc """
  Returns 'true' if the passed AST describes a variable.
  The variable itself is not evaluated, nor checked if it exists in the given context.
  """
  defmacro is_var(value) do
    quote do
      is_tuple(unquote(value)) and is_atom(elem(unquote(value), 0)) and is_atom(elem(unquote(value), 2))
    end
  end

  @doc """
  Returns true if the passed value is a constant
  Either a number, or a mathematical constant such as `e` or `pi`.
  """
  defmacro is_constant(value) do
    quote do
      is_number(unquote(value)) or (is_var(unquote(value)) and elem(unquote(value), 0) in [:e, :pi, :tau])
    end
  end
end