defmodule Symmath do
  import Symmath.Guards


  defmodule Expr do
    defstruct [:ast]
  
    defimpl Inspect do
      def inspect(expr, _opts) do
        ast_str = Macro.to_string(expr.ast)
        "Symmath.expr(#{ast_str})"
      end
    end
  end

  @mathematical_constants [:pi, :e, :tau]

  def __using__(_opts) do
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
  Attempts to simplify the expression using some very basic rewriting rules.
  """
  def simplify(expression) do
    Symmath.Simplify.simplify(expression)
  end

  @doc """
  Attempts to obtain the derivative of a given expression.
  Note that the implementation is probably incomplete.
  """
  def deriv(expression) do
    Symmath.Derivative.deriv(expression)
  end

end
