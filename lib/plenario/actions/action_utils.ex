defmodule Plenario.ActionUtils do

  def params_to_map(params) do
    params
    |> Enum.map(fn {key, value} ->
      {String.to_atom("#{key}"), value}
    end)
    |> Enum.into(%{})
  end

  def parse_relation(params, rel, id \\ :id) do
    relid = String.to_atom("#{rel}_#{id}")
    case Map.get(params, relid) do
      nil ->
        case Map.get(params, rel) do
          nil ->
            params

          strukt ->
            value = Map.get(strukt, id)
            Map.put(params, relid, value)
        end

      _ ->
        params
    end
  end
end
