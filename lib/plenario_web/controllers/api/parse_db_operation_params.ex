defmodule PlenarioWeb.Api.ParseDbOperationParams do
  use PlenarioWeb, :api_controller
  import PlenarioWeb.Api.Utils, only: [to_naive_datetime: 1]

  @db_operation_keys ["updated_at", "inserted_at"]

  def init(default) do
    default
  end

  def call(conn, _options) do
    {params, _} =
      Map.get(conn, :params)
      |> Map.split(@db_operation_keys)

    params = Enum.map(params, fn {key, value} ->
      {operator, datetime_str} = String.split(value, ":", parts: 2)
      {key, {operator, case to_naive_datetime(datetime_str) do
        {:ok, naive_datetime} ->
          {String.to_atom(key), naive_datetime}
        {:error, _message} ->
          # put the message into the meta error list
          nil
      end}}
    end)

    assign(conn, :db_operation_params, Enum.filter(params, &(&1)))
  end
end
