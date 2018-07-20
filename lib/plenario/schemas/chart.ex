defmodule Plenario.Schemas.Chart do
  use Ecto.Schema

  import Ecto.Changeset

  import Ecto.Query

  alias Plenario.Repo

  alias Plenario.Schemas.Chart

  schema "charts" do
    belongs_to :meta, Plenario.Schemas.Meta
    field :title, :string
    field :type, :string
    field :timestamp_field, :string               # which field do we filter time ranges on
    field :point_field, :string                   # which field do we filter location on
    field :group_by_field, :string, default: nil  # which field do we group by / aggregate
    has_many :datasets, Plenario.Schemas.ChartDataset
  end

  @types ["line", "bar", "pie", "doughnut", "radar", "polarArea"]

  @type_choices [
    Line: "line",
    Bar: "bar",
    Pie: "pie",
    Doughnut: "doughnut",
    Radar: "radar",
    Polar: "polarArea",
  ]

  def get_types, do: @types

  def get_type_choices, do: @type_choices

  # changeset

  @changeset_keys [:meta_id, :title, :type, :timestamp_field, :point_field, :group_by_field]

  def changeset(chart \\ %Chart{}, params \\ %{}) do
    chart
    |> cast(params, @changeset_keys)
    |> foreign_key_constraint(:meta_id)
    |> validate_required([:meta_id, :title, :type, :timestamp_field, :point_field])
    |> validate_inclusion(:type, Chart.get_types())
  end

  # querying

  def list_for_meta(meta_id) do
    Repo.all(
      from c in Chart,
      where: c.meta_id == ^meta_id,
      preload: [datasets: :chart]
    )
  end
end
