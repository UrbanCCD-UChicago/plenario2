defmodule PlenarioAot.AotData do
  use Ecto.Schema

  import Ecto.Changeset

  alias PlenarioAot.AotData

  @derive [Poison.Encoder]
  schema "aot_data" do
    field :aot_meta_id, :id
    field :node_id, :string
    field :human_address, :string
    field :latitude, :float
    field :longitude, :float
    field :timestamp, :naive_datetime
    field :observations, :map
    field :location, Geo.Point
    timestamps()
  end

  def changeset(params) do
    case is_map(params) do
      true -> do_changeset(params)
      false -> do_changeset(Enum.into(params, %{}))
    end
  end

  defp do_changeset(params) do
    %AotData{}
    |> cast(params, [:aot_meta_id, :node_id, :human_address, :latitude, :longitude, :timestamp, :observations])
    |> validate_required([:aot_meta_id, :node_id, :human_address, :latitude, :longitude, :timestamp, :observations])
    |> put_location()
  end

  defp put_location(%Ecto.Changeset{valid?: true} = changeset) do
    lat = get_field(changeset, :latitude)
    lon = get_field(changeset, :longitude)
    point = %Geo.Point{coordinates: {lon, lat}, srid: 4326}
    put_change(changeset, :location, point)
  end
  defp put_location(changeset), do: changeset
end
