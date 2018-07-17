defmodule Plenario.Schemas.ChartDataset do
  use Ecto.Schema

  import Ecto.Changeset

  alias Plenario.Schemas.ChartDataset

  schema "chart_datasets" do
    belongs_to :chart, Plenario.Schemas.Chart
    field :label, :string         # what should we call this data
    field :field_name, :string    # what is the field name we're operating on
    field :func, :string          # what agg func are we applying
    field :color, :string         # what color is used in the chart
    field :fill?, :boolean        # if available, should we fill the area
  end

  @funcs ["avg", "min", "max", "count"]

  @func_choices [
    Average: "avg",
    Minimum: "min",
    Maximum: "max",
    Count: "count"
  ]

  def get_funcs, do: @funcs

  def get_func_choices, do: @func_choices

  @colors [
    "255,99,132",
    "54,162,235",
    "255,206,86",
    "75,192,192",
    "153,102,255",
    "255,159,64"
  ]

  @color_choices [
    Red: "255,99,132",
    Blue: "54,162,235",
    Yellow: "255,206,86",
    Green: "75,192,192",
    Purple: "153,102,255",
    Orange: "255,159,64"
  ]

  def get_colors, do: @colors

  def get_color_choices, do: @color_choices

  @changeset_keys [:chart_id, :label, :field_name, :func, :color, :fill?]

  def changeset(dataset \\ %ChartDataset{}, params \\ %{}) do
    dataset
    |> cast(params, @changeset_keys)
    |> foreign_key_constraint(:chart_id)
    |> validate_inclusion(:func, ChartDataset.get_funcs())
    |> validate_inclusion(:color, ChartDataset.get_colors())
  end
end
