defmodule ListHelper do
  def non_empty_lists_of_equal_length?(xs, ys) do
    length(xs) == length(ys)
  end

  def unique?([]), do: false

  def unique?(xs) do
    xs |> Enum.uniq() |> length == length(xs)
  end

  def equalize_length(xs, ys) do
    min_length = Enum.min([length(xs), length(ys)])
    {Enum.take(xs, min_length), Enum.take(ys, min_length)}
  end

  def between?(value, minimum, maximum) do
    value >= minimum and value <= maximum
  end
end

│ 0.52978 │
│ 0.53436 │
│ 0.58145 │
│ 0.17112 │
│  0.4419 │
│ 0.04821 │
│ 0.31246 │
│ 0.67237 │
│ 0.83706 │
│ 0.74092 │
