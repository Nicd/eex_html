defmodule EExHTML.Engine do
  @moduledoc ~S"""
  An engine for templating HTML content.

  Interpolated values are HTML escaped,
  unless the term implements the `EExHTML.Safe` protocol.

  Values returned are `io_lists` for performance reasons.

  ## Examples

      iex> EEx.eval_string("foo <%= bar %>", [bar: "baz"], engine: EExHTML.Engine)
      ...> |> IO.iodata_to_binary()
      "foo baz"

      iex> EEx.eval_string("foo <%= bar %>", [bar: "<script>"], engine: EExHTML.Engine)
      ...> |> IO.iodata_to_binary()
      "foo &lt;script&gt;"

      iex> EEx.eval_string("foo <%= bar %>", [bar: EExHTML.raw("<script>")], engine: EExHTML.Engine)
      ...> |> IO.iodata_to_binary()
      "foo <script>"

      iex> EEx.eval_string("foo <%= @bar %>", [assigns: %{bar: "<script>"}], engine: EExHTML.Engine)
      ...> |> IO.iodata_to_binary()
      "foo &lt;script&gt;"

      # iex> EEx.eval_string("<%= for _ <- 1..1 do %><p><%= bar %></p><% end %>", [bar: "<script>"], engine: EExHTML.Engine)
      # # ...> |> IO.iodata_to_binary()
      # "foo &lt;script&gt;"

      iex> EEx.eval_string("<%= for _ <- 1..1 do %><p><% end %>", [bar: "<script>"], engine: EExHTML.Engine)
      # ...> |> IO.iodata_to_binary()
      "foo &lt;script&gt;"
  """
  use EEx.Engine

  def init(_options) do
    quote do: []
    # quote do: EExHTML.raw([])
  end

  def handle_begin(_previous) do
    # quote do: EExHTML.raw([])
    quote do: []
  end

  def handle_end(quoted) do
    quoted
  end

  def handle_text(buffer, text) do
    quote do
      [unquote(buffer) | unquote(text)]
      # EExHTML.raw([unquote(buffer).data | unquote(text)])
    end
  end

  def handle_body(quoted) do
    quoted
  end

  def handle_expr(buffer, "=", expr) do
    expr = Macro.prewalk(expr, &EEx.Engine.handle_assign/1)

    # The problem is that a for comprehension returns a list of data.
    # If wrapping is used, as in the comments here, then the list comprehension returns a list of safe content.
    # We could special case this handle expr to know to not escape if given a list of safe content.
    # phoenix_html does a thing where it recursivly tries to make safe all parts of an iolist.
    # This might be overkill, I can't think of a reason to go more than one level deep but it might be more robust.
    quote do
      [unquote(buffer), EExHTML.escape(unquote(expr)).data]

      IO.inspect(unquote(expr))

      # EExHTML.raw([unquote(buffer).data, EExHTML.escape(unquote(expr)).data])
      |> IO.inspect()
    end
  end

  def handle_expr(buffer, "", expr) do
    expr = Macro.prewalk(expr, &EEx.Engine.handle_assign/1)

    quote do
      tmp2 = unquote(buffer)
      unquote(expr)
      tmp2
    end
  end

  def handle_expr(buffer, type, expr) do
    super(buffer, type, expr)
  end
end
