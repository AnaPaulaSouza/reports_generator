defmodule ReportsGenerator do
  @moduledoc """
    Projeto 1
      Módulo para parsear os valores.
  """

  alias ReportsGenerator.Parser

  #Variavel de modulo - funciona dentro do modulo que tiver o @available_foods
  @available_foods [
    "açaí",
    "churrasco",
    "esfirra",
    "hambúrguer",
    "pastel",
    "pizza",
    "prato_feito",
    "sushi"
  ]

  @options ["foods", "users"]

  def build(filename) do
    filename
    |> Parser.parse_file()
    |> Enum.reduce(report_acc(), fn line, report -> sum_values(line, report) end)
  end

  @doc """
    Para medir o tempo de execução:
    ex:
    iex(12)> :timer.tc(fn -> ReportsGenerator.build("report_complete.csv") end)
    {669864,
      %{ "foods" => %{ ... } }

    iex(12)> :timer.tc(fn -> ReportsGenerator.build_from_many(["report_1.csv", "report_2.csv", "report_3.csv"]) end)
    {205248,
      %{ "foods" => %{ ... } }
  """
  def build_from_many(filenames) when not is_list(filenames) do
    {:error, "Please provide a list of strigs"}
  end

  def build_from_many(filenames) do
    result = filenames
    |> Task.async_stream(&build/1)
    |> Enum.reduce(report_acc(), fn {:ok, result}, report -> sum_reports(report, result) end)

    {:ok, result}
  end

  def fetch_higher_cost(report, option) when option in @options do
    {:ok, Enum.max_by(report[option], fn {_key, value} -> value end)}
  end

  def fetch_higher_cost(_report, _option), do: {:erros, "Invalid option!"}

  defp sum_values([id, food_name, price], %{"foods" => foods, "users" => users}) do
    users = Map.put(users, id, users[id] + price)
    foods = Map.put(foods, food_name, foods[food_name] + 1)

    build_report(foods, users)
  end

  defp sum_reports(
         %{"foods" => foods1, "users" => users1},
         %{"foods" => foods2, "users" => users2}) do
    foods = merge_maps(foods1, foods2)
    users = merge_maps(users1, users2)

    build_report(foods, users)
  end

  defp merge_maps(map1, map2) do
    Map.merge(map1, map2, fn _key, value1, value2 -> value1 + value2  end)
  end

  defp report_acc do
    foods = Enum.into(@available_foods, %{}, &{&1, 0})
    users = Enum.into(1..30, %{}, &{Integer.to_string(&1), 0})

    %{"users" => users, "foods" => foods}
  end

  defp build_report(foods, users), do: %{"foods" => foods, "users" => users}
end
