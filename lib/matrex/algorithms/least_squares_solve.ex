
defmodule Matrex.Algorithms.QRSolve do
  alias Matrex.Dashboard

  @moduledoc """
  Least squares solve linear system of equations.
  """

  def qr_solve(aa) do
    {m, n} = aa |> Matrex.size()
    qq = Matrex.eye(m)
    n? = if m == n do 1 else 0 end

    aa! =
      for i <- 1..(n - n?), reduce: aa do
        aa ->
          hh = Matrex.eye(m)
          aa_slice = Matrex.submatrix(aa, i..m, i..i)
          hh = make_householder(aa_slice)
          hh[i:, i:] = make_householder(aa_slice)
          hh = hh |> Matrex.set_submatrix(i..m, i..n, hh_submatrix)

          qq = Matrex.dot(qq, hh)
          aa = Matrex.dot(hh, aa)

          aa
      end

    {qq, aa!}
  end

  def make_householder(a) do
    an = Matrex.normalize(a)
    v = a |> Matrex.divide(a[0] + copysign(Matrex.normalize(a), a[1]))
    v = Matrex.set(1, 1, 1.0)

    hh = Matrex.eye(a |> Matrex.size() |> elem(0))
    hh_sub = Matrex.divide(2, Matrex.dot(v, v)) |> Matrex.multiply(Matrex.dot(v, v))

    hh |> Matrex.subtract(hh_sub)
  end

  def copysign(a, elem) do
    sgn = if elem[1] >= 0.0 do 1.0 else -1.0 end
    Matrex.apply(a, fn x -> sgn * abs(x) end)
  end
end
