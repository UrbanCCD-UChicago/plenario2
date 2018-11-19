defmodule Plenario.DataSet do
  use Ecto.Schema

  import Ecto.Changeset

  import Plenario.SchemaUtils

  alias Ecto.Changeset

  alias Plenario.{
    User,
    DataSet,
    Field,
    VirtualDate,
    VirtualPoint
  }

  schema "data_sets" do
    belongs_to :user, User
    field :name, :string
    field :slug, :string
    field :table_name, :string
    field :view_name, :string
    field :temp_name, :string

    field :soc_4x4, :string, default: nil
    field :soc_domain, :string, default: nil
    field :socrata?, :boolean
    field :src_type, :string, default: nil
    field :src_url, :string, default: nil

    field :state, :string, default: "new"

    field :attribution, :string, default: nil
    field :description, :string, default: nil

    field :refresh_starts_on, :naive_datetime, default: nil
    field :refresh_ends_on, :naive_datetime, default: nil
    field :refresh_interval, :string, default: nil
    field :refresh_rate, :integer, default: nil
    field :first_import, :naive_datetime, default: nil
    field :latest_import, :naive_datetime, default: nil
    field :next_import, :naive_datetime, default: nil

    field :bbox, Geo.Geometry, default: nil
    field :hull, Geo.Geometry, default: nil
    field :time_range, Plenario.TsRange, default: nil
    field :num_records, :integer, default: nil

    has_many :fields, Field
    has_many :virtual_dates, VirtualDate
    has_many :virtual_points, VirtualPoint
  end

  # Easy HTML dumping

  defimpl Phoenix.HTML.Safe, for: DataSet, do: def to_iodata(ds), do: ds.name

  def src_type_choices, do: [CSV: "csv", TSV: "tsv"]

  def refresh_interval_choices, do: ["": nil, Minutes: "minutes", Hours: "hours", Days: "days", Weeks: "weeks", Months: "months", Years: "years"]

  # CHANGESET

  @attrs ~w|user_id name state soc_domain soc_4x4 src_url src_type socrata? attribution description refresh_starts_on refresh_ends_on refresh_rate refresh_interval first_import next_import latest_import bbox hull time_range num_records|a

  @reqd ~w|user_id name state src_type socrata?|a

  @states ~w|new awaiting_approval awaiting_first_import ready erred|

  @src_types ~w|csv tsv json|

  @refresh_intervals ~w|minutes hours days weeks months years|

  @refresh_rate_min 0

  @name_max 58

  @soc_4x4_regex ~r/^\w{4}\-\w{4}$/

  @soc_domain_regex ~r/^^((?!http).)*$$/

  @src_url_regex ~r/^https:\/\/.*$/

  @soc_src_msg "cannot set both web resource and Socrata resource information -- they are mutually exclusive"

  @unreachable_msg "cannot resolve given route information"

  @invalidates_not_new_state ~w|name src_url src_type soc_domain soc_4x4|a

  @invalid_bc_state_msg "cannot make selected changes after state is no longer new"

  @doc false
  def changeset(data_set, params) do
    params =
      params
      |> randomize_time(:refresh_starts_on)
      |> randomize_time(:refresh_ends_on)

    data_set
    |> cast(params, @attrs)
    # vlaidations
    |> validate_required(@reqd)
    |> validate_inclusion(:state, @states)
    |> validate_inclusion(:src_type, @src_types)
    |> validate_inclusion(:refresh_interval, @refresh_intervals)
    |> validate_number(:refresh_rate, greater_than: @refresh_rate_min)
    |> validate_length(:name, max: @name_max)
    |> validate_format(:src_url, @src_url_regex)
    |> validate_format(:soc_domain, @soc_domain_regex)
    |> validate_format(:soc_4x4, @soc_4x4_regex)
    # custom validation
    |> validate_soc_or_src()
    |> validate_src_url()
    |> validate_soc_fields()
    |> validate_changes_regarding_state(data_set.state)
    # putting stuff
    |> put_slug()
    |> put_table_name()
    |> put_view_name()
    |> put_temp_name()
    # constraint capturing
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:name)
    |> unique_constraint(:src_url)
    |> unique_constraint(:soc_4x4, name: :soc_uniq)
  end

  defp randomize_time(params, key) do
    case Map.get(params, key) do
      nil ->
        params

      "" ->
        params

      date ->
        ndt =
          Timex.parse!(date, "%Y-%m-%d", :strftime)
          |> Timex.to_naive_datetime()
          |> Timex.shift(hours: :rand.uniform(23))
          |> Timex.shift(minutes: :rand.uniform(59))
          |> Timex.shift(seconds: :rand.uniform(59))

        Map.put(params, key, ndt)
    end
  end

  defp validate_soc_or_src(changeset) do
    src_url? = get_field(changeset, :src_url)
    soc_dom? = get_field(changeset, :soc_domain)

    cond do
      !is_nil(src_url?) and is_nil(soc_dom?) -> changeset
      is_nil(src_url?) and !is_nil(soc_dom?) -> changeset
      true ->
        add_error(changeset, :src_url, @soc_src_msg)
        |> add_error(:soc_domain, @soc_src_msg)
        |> add_error(:soc_4x4, @soc_src_msg)
    end
  end

  defp validate_src_url(%Changeset{valid?: true, changes: %{src_url: url}} = changeset) do
    %HTTPoison.Response{status_code: opts} = HTTPoison.options!(url)
    case opts in [200, 204] do
      true ->
        changeset

      false ->
        %HTTPoison.Response{status_code: head} = HTTPoison.head!(url)
        case head in [200, 204] do
          true ->
            changeset

          false ->
            add_error(changeset, :src_url, @unreachable_msg)
        end
    end
  end

  defp validate_src_url(c), do: c

  defp validate_soc_fields(%Changeset{valid?: true} = changeset) do
    domain = get_change(changeset, :soc_domain)
    four_by = get_change(changeset, :soc_4x4)

    do_validate_soc_fields(changeset, domain, four_by)
  end

  defp validate_soc_fields(changeset), do: changeset

  defp do_validate_soc_fields(changeset, nil, nil), do: changeset

  defp do_validate_soc_fields(changeset, domain, four_by) do
    resp =
      Exsoda.Reader.query(four_by, domain: domain)
      |> Exsoda.Reader.get_view()

    case resp do
      {:ok, _} -> changeset
      {:error, _} ->
        add_error(changeset, :soc_4x4, @unreachable_msg)
        |> add_error(:soc_domain, @unreachable_msg)
    end
  end

  defp validate_changes_regarding_state(changeset, "new"), do: changeset

  defp validate_changes_regarding_state(%Changeset{changes: changes} = changeset, _state) do
    Map.keys(changes)
    |> Enum.reduce(changeset, fn key, acc ->
      case Enum.member?(@invalidates_not_new_state, key) do
        false -> acc
        true -> add_error(acc, key, @invalid_bc_state_msg)
      end
    end)
  end

  defp put_slug(%Changeset{valid?: true, changes: %{name: name}} = changeset), do: put_change(changeset, :slug, slugify(name))
  defp put_slug(changeset), do: changeset

  defp put_table_name(%Changeset{changes: %{slug: slug}} = changeset), do: put_change(changeset, :table_name, postgresify(slug))
  defp put_table_name(changeset), do: changeset

  defp put_view_name(%Changeset{changes: %{table_name: table_name}} = changeset), do: put_change(changeset, :view_name, "#{table_name}_view")
  defp put_view_name(changeset), do: changeset

  defp put_temp_name(%Changeset{changes: %{table_name: table_name}} = changeset), do: put_change(changeset, :temp_name, "#{table_name}_temp")
  defp put_temp_name(changeset), do: changeset
end
