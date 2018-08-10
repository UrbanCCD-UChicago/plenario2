defmodule PlenarioWeb.Api.ViewUtils do
  def clean(records) when is_list(records) do
    clean(records, [])
  end

  def clean(record) when is_map(record) do
    Map.to_list(record)
    |> Enum.filter(fn {key, value} -> is_clean(key, value) end)
    |> Map.new()
  end

  defp clean([], acc) do
    Enum.reverse(acc)
  end

  defp clean([head | tail], acc) do
    cleaned = clean(head)
    clean(tail, [cleaned | acc])
  end

  defp is_clean(_, %Ecto.Association.NotLoaded{}), do: false
  defp is_clean(_, %Plug.Conn{}), do: false

  defp is_clean(key, _)
       when key in [
              :__meta__,
              :__struct__,
              :id,
              :inserted_at,
              :updated_at,
              :source_type,
              :table_name,
              :state,
              :user_id
            ],
       do: false

  defp is_clean(_, _), do: true
end
