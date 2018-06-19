defmodule PlenarioAot.AotMeta do
  use Ecto.Schema

  import Ecto.Changeset

  alias PlenarioAot.{AotData, AotMeta}

  @derive [Poison.Encoder]
  schema "aot_metas" do
    field :network_name, :string
    field :slug, :string
    field :source_url, :string
    field :bbox, Geo.Polygon
    field :time_range, Plenario.TsRange
    timestamps()

    has_many :data, AotData
  end

  def changeset(meta \\ %AotMeta{}, params \\ []) do
    case is_map(params) do
      true -> do_changeset(meta, params)
      false -> do_changeset(meta, Enum.into(params, %{}))
    end
  end

  defp do_changeset(meta, params) do
    meta
    |> cast(params, [:network_name, :source_url, :bbox, :time_range])
    |> validate_required([:network_name, :source_url])
    |> unique_constraint(:network_name)
    |> unique_constraint(:source_url)
    |> put_slug()
  end

  defp extract_non_ascii(string) do
    Regex.scan(~r/[^\x00-\x7F]/, string)
    |> List.to_string()
  end

  defp put_slug(%Ecto.Changeset{valid?: true} = changeset) do
    name = get_field(changeset, :network_name)
    ignore = extract_non_ascii(name)
    slug = Slug.slugify(name, ignore: ignore)
    put_change(changeset, :slug, slug)
  end
  defp put_slug(changeset), do: changeset
end
