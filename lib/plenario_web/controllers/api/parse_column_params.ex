defmodule PlenarioWeb.Controllers.Api.ParseColumnParams do
  use PlenarioWeb, :api_controller
  import PlenarioWeb.Api.Utils, only: [to_naive_datetime: 1]
  alias Plenario.Actions.MetaActions

  def init(default) do
    default
  end

  def call(conn, _options) do
    columns_and_types =
      conn.params["slug"]
      |> MetaActions.get()
      |> MetaActions.get_column_names_and_types()

    columns = for {column, _} <- columns_and_types, do: column
    column_type_map = Map.new(columns_and_types)

    {params, _} =
      Map.get(conn, :params)
      |> Map.split(columns)

    column_params = Enum.map(params, fn {key, value} ->
      [operator, operand] = String.split(value, ":", parts: 2)
      casted_operand = cast(operand, column_type_map[key])
      {key, {operator, casted_operand}}
    end)

    assign(conn, :column_params, column_params)
  end

  defp cast(value, "float") do
    {float, _} = Float.parse(value)
    float
  end

  defp cast(value, "integer") do
    {integer, _} = Integer.parse(value)
    integer
  end

  defp cast(value, "datetime") do
    to_naive_datetime(value)
  end

  defp cast(value, _) do
    value
  end
end
