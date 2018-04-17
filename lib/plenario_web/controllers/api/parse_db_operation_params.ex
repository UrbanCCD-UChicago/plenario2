# todo(heyzoos) given the similarity of this plug to `parse_pagination_params.ex`, and depending on
# todo(heyzoos) how similar this is to Sanil's implementation, might be able to abstract this into
# todo(heyzoos) a single module that takes keys as an argument
defmodule PlenarioWeb.Api.ParseDbOperationParams do
  use PlenarioWeb, :api_controller

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

  def to_naive_datetime(string) do
    case Date.from_iso8601(string) do
      {:ok, date} ->
        date_erl = Date.to_erl(date)
        {:ok, NaiveDateTime.from_erl!({date_erl}, {0, 0, 0})}
      {:error, _} ->
        case NaiveDateTime.from_iso8601(string) do
          {:ok, datetime} -> {:ok, datetime}
          {:error, message, _} -> {:error, message}
        end
    end
  end
end
