defmodule PlenarioWeb.Api.ParsePaginationParams do
  use PlenarioWeb, :api_controller

  @pagination_keys ["page", "page_size"]

  def init(default) do
    default
  end

  def call(conn, _options) do
    {pagination_params, _} =
      Map.get(conn, :params)
      |> Map.split(@pagination_keys)

    pagination_params = Enum.map(pagination_params, fn {key, value} ->
      {value, _} = Integer.parse(value)
      {String.to_atom(key), value}
    end)

    assign(conn, :pagination_params, pagination_params)
  end
end
