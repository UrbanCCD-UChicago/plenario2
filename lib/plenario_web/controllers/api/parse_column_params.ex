defmodule PlenarioWeb.Controllers.Api.ParseColumnParams do
  use PlenarioWeb, :api_controller
  alias Plenario.Actions.MetaActions

  def init(default) do
    default
  end

  def call(conn, _options) do
    columns =
      conn.params["slug"]
      |> MetaActions.get()
      |> MetaActions.get_column_names()

    {params, _} =
      conn.params
      |> Enum.map(fn {key, value} -> {URI.decode(key), URI.decode(value)} end)
      |> Map.new()
      |> Map.split(columns)

    column_params = Enum.map(params, fn {column, value} ->
      [operator, operand] = String.split(value, ":", parts: 2)

      case Poison.decode(operand) do
        {:ok, map} -> {column, {operator, map}}
        {:error, _} -> {column, {operator, operand}}
      end
    end)

    assign(conn, :column_params, column_params)
  end
end
