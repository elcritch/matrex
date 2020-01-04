defmodule Matrex.Algorithms.Statistics do
  @moduledoc """
  Common statistical functions.
  """

  import Matrex.Guards

  @doc """
  The average of a list of numbers.
  """
  @spec mean(Common.vector()) :: Common.maybe_float()

  def mean(x = %Matrex{}) do
    sum(x) / Enum.count(x.items)
  end

  def mean(xs) do
    x = Matrex.new(xs)
    mean(x)
  end

  @doc """
  The middle value in a list of numbers.
  """
  @spec median(Common.vector()) :: Common.maybe_float()

  def median(x = %Matrex{}) do
    middle_index = round(length(x.items) / 2) - 1
    x.items |> Enum.sort() |> Enum.at(middle_index)
  end

  def median(xs) do
    x = Matrex.new(xs)
    median(x)
  end

  @doc """
  The most frequent value(s) in a list.
  """
  @spec mode(Common.vector()) :: Common.maybe_vector()

  def mode(x = %Matrex{}) do
    counts =
      Enum.reduce(x.items, %{}, fn i, acc ->
        acc |> Map.update(i, 1, fn count -> count + 1 end)
      end)

    {_, max_count} = counts |> Enum.max_by(fn {_x, count} -> count end)

    case max_count do
      1 ->
        nil

      _ ->
        counts
        |> Stream.filter(fn {_x, count} -> count == max_count end)
        |> Enum.map(fn {i, _count} -> i end)
    end
  end

  def mode(xs) do
    x = Matrex.new(xs)
    mode(x)
  end

  @doc """
  The difference between the largest and smallest values in a list.
  """
  @spec range(Common.vector()) :: Common.maybe_float()

  def range(x = %Matrex{}) do
    {minimum, maximum} = Enum.min_max(x.items)
    maximum - minimum
  end

  def range(xs) do
    x = Matrex.new(xs)
    range(x)
  end

  @doc """
  The unbiased population variance from a sample.
  It measures how far the vector is spread out from the mean.
  """
  @spec variance(Common.vector()) :: Common.maybe_float()
  def variance(
        matrex_data(rows1, columns1, _data1, _first)
      ) when rows1 <= 1 or columns1 <= 1,
      do: raise %ArgumentError{message: "incorrect sizes"}

  def variance(x = %Matrex{}) do
    sum_powered_deviations(x, 2) / (Enum.count(x.items) - 1)
  end

  def variance(xs) do
    x = Matrex.new(xs)
    variance(x)
  end

  @doc """
  The variance for a full population.
  It measures how far the vector is spread out from the mean.
  """
  @spec population_variance(Common.vector()) :: Common.maybe_float()
  def population_variance(x = %Matrex{}), do: moment(x, 2)

  def population_variance(xs) do
    x = Matrex.new(xs)
    population_variance(x)
  end

  @doc """
  The unbiased standard deviation from a sample.
  It measures the amount of variation of the vector.
  """
  @spec std_dev(Common.vector()) :: Common.maybe_float()
  def std_dev(
        matrex_data(rows1, columns1, _data1, _first)
      ) when rows1 <= 1 or columns1 <= 1,
      do: raise %ArgumentError{message: "incorrect sizes"}
  def std_dev(x = %Matrex{}), do: :math.sqrt(variance(x))

  def std_dev(xs) do
    x = Matrex.new(xs)
    std_dev(x)
  end

  @doc """
  The standard deviation for a full population.
  It measures the amount of variation of the vector.
  """
  @spec population_std_dev(Common.vector()) :: Common.maybe_float()
  def population_std_dev(x = %Matrex{}), do: :math.sqrt(population_variance(x))

  def population_std_dev(xs) do
    x = Matrex.new(xs)
    population_std_dev(x)
  end

  @doc """
  The nth moment about the mean for a sample.
  Used to calculate skewness and kurtosis.
  """
  @spec moment(Common.vector(), pos_integer) :: Common.maybe_float()
  def moment(_, 1), do: 0.0
  def moment(x = %Matrex{}, n), do: sum_powered_deviations(x, n) / Enum.count(x.items)

  def moment(xs, n) do
    x = Matrex.new(xs)
    moment(x, n)
  end

  @doc """
  The sharpness of the peak of a frequency-distribution curve.
  It defines the extent to which a distribution differs from a normal distribution.
  Like skewness, it describes the shape of a probability distribution.
  """
  @spec kurtosis(Common.vector()) :: Common.maybe_float()
  def kurtosis(x = %Matrex{}), do: moment(x, 4) / :math.pow(population_variance(x), 2) - 3

  def kurtosis(xs) do
    x = Matrex.new(xs)
    kurtosis(x)
  end

  @doc """
  The skewness of a frequency-distribution curve.
  It defines the extent to which a distribution differs from a normal distribution.
  Like kurtosis, it describes the shape of a probability distribution.
  """
  @spec skewness(Common.vector()) :: Common.maybe_float()
  def skewness(x = %Matrex{}), do: moment(x, 3) / :math.pow(population_variance(x), 1.5)

  def skewness(xs) do
    x = Matrex.new(xs)
    skewness(x)
  end

  @doc """
  Calculates the unbiased covariance from two sample vectors.
  It is a measure of how much the two vectors change together.
  """
  @spec covariance(Common.vector(), Common.vector()) :: Common.maybe_float()
  def covariance(
        matrex_data(rows1, columns1, _data1, _first)
      ) when rows1 <= 1 or columns1 <= 1,
      do: raise %ArgumentError{message: "incorrect sizes"}
  def covariance(
        matrex_data(rows1, columns1, _data1, _first)
      ) when rows1 != columns1,
      do: raise %ArgumentError{message: "incorrect sizes"}

  def covariance(x = %Matrex{}, y = %Matrex{}) do
    divisor = Enum.count(x.items) - 1
    do_covariance(x, y, divisor)
  end

  def covariance(xs, ys) do
    x = Matrex.new(xs)
    y = Matrex.new(ys)
    covariance(x, y)
  end

  @doc """
  Calculates the population covariance from two full population vectors.
  It is a measure of how much the two vectors change together.
  """
  @spec population_covariance(Common.vector(), Common.vector()) :: Common.maybe_float()

  def population_covariance(
        matrex_data(rows1, columns1, _data1, _first),
        matrex_data(rows2, columns2, _data2, _second)
      ) when rows1 != rows2 or columns1 != columns2,
      do: raise %ArgumentError{message: "incorrect sizes"}

  def population_covariance(x = %Matrex{}, y = %Matrex{}) do
    divisor = Enum.count(x.items)
    do_covariance(x, y, divisor)
  end

  def population_covariance(xs, ys) do
    x = Matrex.new(xs)
    y = Matrex.new(ys)
    population_covariance(x, y)
  end

  @doc """
  Estimates the tau-th quantile from the vector.
  Approximately median-unbiased irrespective of the sample distribution.
  This implements the R-8 type of https://en.wikipedia.org/wiki/Quantile.
  """
  @spec quantile(Common.vector(), number) :: Common.maybe_float()
  def quantile(_xs, tau) when tau < 0 or tau > 1, do: nil

  def quantile(x = %Matrex{}, tau) do
    sorted_x = Enum.sort(x.items)
    h = (length(sorted_x) + 1 / 3) * tau + 1 / 3
    hf = h |> Float.floor() |> round
    do_quantile(sorted_x, h, hf)
  end

  def quantile(xs, tau) do
    x = Matrex.new(xs)
    quantile(x, tau)
  end

  @doc """
  Estimates the p-Percentile value from the vector.
  Approximately median-unbiased irrespective of the sample distribution.
  This implements the R-8 type of https://en.wikipedia.org/wiki/Quantile.
  """
  @spec percentile(Common.vector(), integer) :: Common.maybe_float()
  def percentile(_xs, p) when p < 0 or p > 100, do: nil
  def percentile(x = %Matrex{}, p), do: quantile(x, p / 100)

  def percentile(xs, p) do
    x = Matrex.new(xs)
    percentile(x, p)
  end

  @doc """
  Calculates the weighted measure of how much two vectors change together.
  """
  @spec weighted_covariance(Common.vector(), Common.vector(), Common.vector()) ::
          Common.maybe_float()

  def weighted_covariance(
        matrex_data(rows1, columns1, _data1, _first),
        matrex_data(rows2, columns2, _data2, _second),
        matrex_data(rows3, columns3, _data3, _third)
      ) when rows1 != rows2 or rows1 != rows3,
      do: raise %ArgumentError{message: "incorrect sizes"}

  def weighted_covariance(x = %Matrex{}, y = %Matrex{}, w = %Matrex{}) do
    weighted_mean1 = weighted_mean(x, w)
    weighted_mean2 = weighted_mean(y, w)
    sum(w * (x - weighted_mean1) * (y - weighted_mean2)) / sum(w)
  end

  def weighted_covariance(xs, ys, weights) do
    x = Matrex.new(xs)
    y = Matrex.new(ys)
    w = Matrex.new(weights)
    weighted_covariance(x, y, w)
  end

  @doc """
  Calculates the weighted average of a list of numbers.
  """
  @spec weighted_mean(Common.vector(), Common.vector()) :: Common.maybe_float()
  def weighted_mean(
        matrex_data(rows1, columns1, _data1, _first),
        matrex_data(rows2, columns2, _data2, _second)
      ) when rows1 != rows2,
      do: raise %ArgumentError{message: "incorrect sizes"}
  def weighted_mean(x = %Matrex{}, w = %Matrex{}), do: sum(x * w) / sum(w)

  def weighted_mean(xs, weights) do
    x = Matrex.new(xs)
    w = Matrex.new(weights)
    weighted_mean(x, w)
  end

  defp sum_powered_deviations(x, n) do
    x_mean = mean(x)
    sum(pow(x - x_mean, n))
  end

  defp do_covariance(x, y, divisor) do
    mean_x = mean(x)
    mean_y = mean(y)
    sum((x - mean_x) * (y - mean_y)) / divisor
  end

  defp do_quantile([head | _], _h, hf) when hf < 1, do: head
  defp do_quantile(xs, _h, hf) when hf >= length(xs), do: List.last(xs)

  defp do_quantile(xs, h, hf) do
    Enum.at(xs, hf - 1) + (h - hf) * (Enum.at(xs, hf) - Enum.at(xs, hf - 1))
  end
end
