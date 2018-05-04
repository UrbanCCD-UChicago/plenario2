defmodule PlenarioAot.AotObservation do
  use Ecto.Schema

  import Ecto.Changeset

  alias PlenarioAot.AotObservation

  schema "aot_observations" do
    field :aot_data_id, :id
    field :path, :string
    field :sensor, :string
    field :observation, :string
    field :value, :float
  end

  def changeset(params) do
    case is_map(params) do
      true -> do_changeset(params)
      false -> do_changeset(Enum.into(params, %{}))
    end
  end

  defp do_changeset(params) do
    %AotObservation{}
    |> cast(params, [:aot_data_id, :path, :sensor, :observation, :value])
    |> validate_required([:aot_data_id, :path, :sensor, :observation, :value])
  end
end
