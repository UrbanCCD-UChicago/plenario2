defmodule Plenario.Schemas.Meta do
  @moduledoc """
  Defines the schema for Metas
  """

  use Ecto.Schema

  alias Plenario.Schemas.Meta

  use EctoStateMachine,
    states: [:new, :needs_approval, :awaiting_first_import, :ready, :erred],
    events: [
      [
        name: :submit_for_approval,
        from: [:new],
        to: :needs_approval
      ], [
        name: :approve,
        from: [:needs_approval],
        to: :awaiting_first_import
      ], [
        name: :disapprove,
        from: [:needs_approval],
        to: :new
      ], [
        name: :mark_first_import,
        from: [:awaiting_first_import],
        to: :ready
      ], [
        name: :mark_erred,
        from: [:needs_approval, :awaiting_first_import, :ready],
        to: :erred
      ], [
        name: :mark_fixed,
        from: [:erred],
        to: :ready
      ]
    ]

  @refresh_rate_values [
    nil,
    "minutes",
    "hours",
    "days",
    "months",
    "years"
  ]

  @refresh_rate_choices [
    "Don't Refresh": nil,
    Minutes: "minutes",
    Hours: "hours",
    Days: "days",
    Months: "months",
    Years: "years"
  ]

  @source_type_values ["csv", "tsv", "json", "shp"]

  @source_type_choices [
    CSV: "csv",
    TSV: "tsv",
    JSON: "json",
    Shapefile: "shp"
  ]

  schema "metas" do
    field :name, :string
    field :slug, :string
    field :table_name, :string

    field :state, :string, default: "new"

    field :description, :string, default: nil
    field :attribution, :string, default: nil

    field :source_url, :string
    field :source_type, :string

    field :refresh_rate, :string, default: nil
    field :refresh_interval, :integer, default: nil
    field :refresh_starts_on, :date, default: nil
    field :refresh_ends_on, :date, default: nil

    field :first_import, :utc_datetime, default: nil
    field :latest_import, :utc_datetime, default: nil
    field :next_import, :utc_datetime, default: nil

    field :bbox, Geo.Polygon, default: nil
    field :time_range, Plenario.TsTzRange, default: nil

    timestamps(type: :utc_datetime)

    belongs_to :user, Plenario.Schemas.User
    has_many :fields, Plenario.Schemas.DataSetField
    has_many :virtual_dates, Plenario.Schemas.VirtualDateField
    has_many :virtual_points, Plenario.Schemas.VirtualPointField
    has_many :unique_constraints, Plenario.Schemas.UniqueConstraint
  end

  @doc """
  Returns a list of acceptible values for :refresh_rate.
  """
  @spec get_refresh_rate_values() :: list(nil | String.t())
  def get_refresh_rate_values(), do: @refresh_rate_values

  @doc """
  Returns a keyword list of mappings of friendly names and acceptible
  values for :refresh_rate.
  """
  @spec get_refresh_rate_choices() :: Keyword.t()
  def get_refresh_rate_choices(), do: @refresh_rate_choices

  @doc """
  Returns a list of acceptible values for :source_type.
  """
  @spec get_source_type_values() :: list(nil | String.t())
  def get_source_type_values(), do: @source_type_values

  @doc """
  Returns a keyword list of mappings of friendly names and acceptible
  values for :source_type.
  """
  @spec get_source_type_choices() :: Keyword.t()
  def get_source_type_choices(), do: @source_type_choices

  @doc """
  Returns a friendly string for displaying refresh interval and rate.
  """
  @spec get_refresh_cadence(meta :: Meta) :: String.t()
  def get_refresh_cadence(meta) do
    if meta.refresh_rate do
      if meta.refresh_interval > 1 do
        "#{meta.refresh_interval} #{meta.refresh_rate}s"
      else
        "#{meta.refresh_interval} #{meta.refresh_rate}"
      end
    else
      "-"
    end
  end

  def get_time_range_string(%Meta{time_range: nil}), do: "-"
  def get_time_range_string(%Meta{time_range: [lower, upper]}) do
    "#{lower} to #{upper}"
  end
end
