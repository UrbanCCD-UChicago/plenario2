defmodule PlenarioAot.AotActions do
  require Logger

  import Ecto.Query

  alias Plenario.Repo

  alias PlenarioAot.{AotMeta, AotData, AotObservation}

  def create_meta(network_name, source_url) do
    params = %{network_name: network_name, source_url: source_url}
    meta = %AotMeta{}

    Logger.info("Creating new AoT Meta with params `#{inspect(params)}`")

    AotMeta.changeset(meta, params)
    |> Repo.insert()
  end

  def list_metas, do: Repo.all(AotMeta)

  def get_meta(identifier) when is_integer(identifier), do: Repo.one(AotMeta, id: identifier)
  def get_meta(identifier) when is_bitstring(identifier), do: Repo.one(AotMeta, slug: identifier)

  def update_meta(%AotMeta{} = meta, params \\ []) do
    params = Enum.into(params, %{})

    Logger.info("Updating AoT Meta `#{meta.network_name}` with #{inspect(params)}")

    AotMeta.changeset(meta, params)
    |> Repo.update()
  end

  def compute_and_update_meta_bbox(%AotMeta{} = meta) do
    query =
      from d in AotData,
      where: d.aot_meta_id == ^meta.id,
      select: %{
        min_lat: min(d.latitude),
        max_lat: max(d.latitude),
        min_lon: min(d.longitude),
        max_lon: max(d.longitude)
      }
    res = Repo.one(query)

    case res do
      %{min_lat: min_lat, max_lat: max_lat, min_lon: min_lon, max_lon: max_lon} ->
        bbox = %Geo.Polygon{
          srid: 4326,
          coordinates: [[
            {max_lat, min_lon},
            {min_lat, min_lon},
            {min_lat, max_lon},
            {max_lat, max_lon},
            {max_lat, min_lon}
          ]]
        }

        case update_meta(meta, bbox: bbox) do
          {:ok, _} ->
            :ok

          {:error, cs} ->
            Logger.error("#{inspect(cs)}")
            :ok
        end

      _ ->
        {:error, "No available min/max tuples"}
    end
  end

  def compute_and_update_meta_time_range(%AotMeta{} = meta) do
    query =
      from d in AotData,
      where: d.aot_meta_id == ^meta.id,
      select: %{
        min_ts: min(d.timestamp),
        max_ts: max(d.timestamp)
      }
    res = Repo.one(query)

    case res do
      %{min_ts: min_ts, max_ts: max_ts} ->
        case update_meta(meta, time_range: [min_ts, max_ts]) do
          {:ok, _} ->
            :ok

          {:error, cs} ->
            Logger.error("#{inspect(cs)}")
            :ok
        end

      _ ->
        {:error, "No available timestamp tuple"}
    end
  end

  def insert_data(%AotMeta{} = meta, %{} = json_payload), do: insert_data(meta.id, json_payload)
  def insert_data(meta, json_payload) do
    params = Map.merge(json_payload, %{"aot_meta_id" => meta})

    result =
      AotData.changeset(params)
      |> Repo.insert(on_conflict: :nothing)

    case result do
      {:error, _} ->
        result

      {:ok, data} ->
        insert_observations(data)
        result
    end
  end

  defp insert_observations(%AotData{} = data) do
    paths_values = get_json_paths_and_values(data.observations)

    Enum.each(paths_values, fn {path, value} ->
      [sensor, observation] = String.split(path, ".")
      params = %{
        aot_data_id: data.id,
        path: path,
        sensor: sensor,
        observation: observation,
        value: value
      }

      AotObservation.changeset(params)
      |> Repo.insert(on_conflict: :nothing)
    end)
  end

  defp get_json_paths_and_values(json) when is_map(json), do: json |> Map.to_list() |> to_flat_map(%{})

  defp to_flat_map([{pk, %{} = v} | t], acc), do: v |> to_list(pk) |> to_flat_map(to_flat_map(t, acc))
  defp to_flat_map([{k, v} | t], acc), do: to_flat_map(t, Map.put_new(acc, k, v))
  defp to_flat_map([], acc), do: acc

  defp to_list(map, pk) when is_atom(pk), do: to_list(map, Atom.to_string(pk))
  defp to_list(map, pk) when is_binary(pk), do: Enum.map(map, &update_key(pk, &1))

  defp update_key(pk, {k, v} = _val) when is_atom(k), do: update_key(pk, {Atom.to_string(k), v})
  defp update_key(pk, {k, v} = _val) when is_binary(k), do: {"#{pk}.#{k}", v}
end
