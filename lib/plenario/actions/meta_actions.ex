defmodule Plenario.Actions.MetaActions do
  @moduledoc """
  This module provides a high level API for interacting with Meta structs --
  creation, updating, archiving, admin status, listing...
  """

  alias Plenario.Repo

  alias Plenario.Actions.{
    DataSetActions,
    DataSetFieldActions,
    VirtualDateFieldActions,
    VirtualPointFieldActions
  }

  alias Plenario.Changesets.MetaChangesets

  alias Plenario.Queries.MetaQueries

  alias Plenario.Schemas.{Meta, User}

  @typedoc """
  Either a tuple of {:ok, meta} or {:error, changeset}
  """
  @type ok_meta :: {:ok, Meta} | {:error, Ecto.Changeset.t()}

  @doc """
  This is a convenience function for generating changesets to more easily create
  webforms in Phoenix templates.

  ## Example

    changeset = MetaActions.new()
    render(conn, "create.html", changeset: changeset)
    # And then in your template: <%= form_for @changeset, ... %>
  """
  @spec new() :: Ecto.Changeset.t()
  def new(), do: MetaChangesets.create(%{})

  @doc """
  Create a new Meta entry in the database.

  ## Example

    {:ok, meta} = MetaActions.create("test", user, "https://example.com", "csv")
  """
  @spec create(name :: String.t(), user :: User, source_url :: String.t(), source_type :: String.t()) :: ok_meta
  def create(name, user, source_url, source_type) when not is_integer(user) do
    create(name, user.id, source_url, source_type)
  end

  @spec create(name :: String.t(), user_id :: integer, source_url :: String.t(), source_type :: String.t()) :: ok_meta
  def create(name, user_id, source_url, source_type) when is_integer(user_id) do
    params = %{
      name: name,
      user_id: user_id,
      source_url: source_url,
      source_type: source_type
    }
    MetaChangesets.create(params)
    |> Repo.insert()
  end

  @doc """
  Updates a given Meta's name, source url, source type, description,
  attribution, refresh rate, refresh interval, refresh starts on,
  and/or refresh ends on.

  ## Example

    {:ok, meta} = MetaActions.create("test", user, "https://example.com", "csv")
    {:ok, _} = MetaActions.update(meta, source_url: "https://exmaple.com/new", source_type: "json")
  """
  @spec update(meta :: Meta, opts :: Keyword.t()) :: ok_meta
  def update(meta, opts \\ []) do
    params = Enum.into(opts, %{})
    MetaChangesets.update(meta, params)
    |> Repo.update()
  end

  @doc """
  Updates a given Meta's user relation.

  ## Example

    {:ok, meta} = MetaActions.create("test", user, "https://example.com", "csv")
    {:ok, _} = MetaActions.update_user(meta, someone_else)
  """
  @spec update_user(meta :: Meta, user :: User) :: ok_meta
  def update_user(meta, user) when not is_integer(user) do
    update_user(meta, user.id)
  end

  @spec update_user(meta :: Meta, user_id :: integer) :: ok_meta
  def update_user(meta, user_id) when is_integer(user_id) do
    params = %{user_id: user_id}
    MetaChangesets.update_user(meta, params)
    |> Repo.update()
  end

  @doc """
  Updates a given Meta's latest import attribute.

  ## Example

    {:ok, meta} = MetaActions.create("test", user, "https://example.com", "csv")
    {:ok, _} = MetaActions.update_latest_import(meta, DateTime.utc_now())
  """
  @spec update_latest_import(meta :: Meta, timestamp :: DateTime.t()) :: ok_meta
  def update_latest_import(meta, timestamp) do
    params = %{latest_import: timestamp}
    MetaChangesets.update_latest_import(meta, params)
    |> Repo.update()
  end

  @doc """
  Updates a given Meta's next import attribute.
  """
  @spec update_next_import(meta :: Meta) :: ok_meta
  def update_next_import(meta) do
    current =
      case meta.next_import do
        nil -> DateTime.utc_now()
        _ -> meta.next_refresh
      end

    rate = meta.refresh_rate
    interval = meta.refresh_interval

    shifted = Timex.shift(current, [{String.to_atom(rate), interval}])
    params = %{next_import: shifted}

    MetaChangesets.update(meta, params)
|> Repo.update()
  end

  @doc """
  Updates a given Meta's bounding box.

  ## Example

    bbox = Geo.WKT.decode("POLYGON ((30 10, 40 40, 20 40, 10 20, 30 10))")
    {:ok, meta} = MetaActions.create("test", user, "https://example.com", "csv")
    {:ok, _} = MetaActions.update_bbox(meta, bbox)
  """
  @spec update_bbox(meta :: Meta, bbox :: Geo.Polygon) :: ok_meta
  def update_bbox(meta, bbox) do
    params = %{bbox: bbox}
    MetaChangesets.update_bbox(meta, params)
    |> Repo.update()
  end

  @doc """
  Updates a given Meta's time range attribute.

  ## Example

    {:ok, meta} = MetaActions.create("test", user, "https://example.com", "csv")
    {:ok, _} = MetaActions.update_time_range(meta, ~D[2017-01-01], ~D[2018-01-01])
  """
  @spec update_time_range(meta :: Meta, lower :: DateTime.t(), upper :: DateTime.t()) :: ok_meta
  def update_time_range(meta, lower, upper) do
    params = %{time_range: [lower, upper]}
    MetaChangesets.update_time_range(meta, params)
    |> Repo.update()
  end

  @doc """
  Marks the given Meta as needs approval in the database.
  """
  @spec submit_for_approval(meta :: Meta) :: ok_meta
  def submit_for_approval(meta) do
    Meta.submit_for_approval(meta)
    |> Repo.update()
  end

  @doc """
  Marks the given Meta as approved in the database. It then brings up the
  needed table, functions and triggers for the data set.

  If everything succeeds, this returns {:ok, Meta}; if something goes wrong
  while bringing up the data set, it returns {:error, "message"} and calls
  `mark_erred`.
  """
  @spec approve(meta :: Meta) :: {:ok, Meta} | {:error, String.t()}
  def approve(meta) do
    {:ok, meta} =
      Meta.approve(meta)
      |> Repo.update()

    try do
      DataSetActions.up!(meta)
      {:ok, meta}
    rescue
      e in Postgrex.Error ->
        DataSetActions.down!(meta)
        mark_erred(meta)
        {:error, e.postgres.message}
    end
  end

  @doc """
  Marks the given Meta as new in the database.
  """
  @spec disapprove(meta :: Meta) :: ok_meta
  def disapprove(meta) do
    Meta.disapprove(meta)
    |> Repo.update()
  end

  @doc """
  Marks the given Meta as ready in the database and sets the Meta's first_import
  date to the current timestamp.
  """
  @spec mark_first_import(meta :: Meta) :: ok_meta
  def mark_first_import(meta) do
    MetaChangesets.update_first_import(meta, %{first_import: DateTime.utc_now()})
    |> Repo.update()

    meta = get(meta.id)
    Meta.mark_first_import(meta)
    |> Repo.update()
  end

  @doc """
  Marks the given Meta as erred in the database.
  """
  @spec mark_erred(meta :: Meta) :: ok_meta
  def mark_erred(meta) do
    Meta.mark_erred(meta)
    |> Repo.update()
  end

  @doc """
  Marks the given Meta as ready after having erred in the database.
  """
  @spec mark_fixed(meta :: Meta) :: ok_meta
  def mark_fixed(meta) do
    Meta.mark_fixed(meta)
    |> Repo.update()
  end

  @doc """
  Selects all dates in the data set's table and finds the minimum and maximum
  values. From those values, it creates a TsTzRange.
  """
  @spec compute_time_range!(meta :: Meta) :: {:ok, Plenario.TsTzRange}
  def compute_time_range!(meta) do
    dsfs =
      DataSetFieldActions.list(for_meta: meta)
      |> Enum.filter(fn field -> field.type == "timestamptz" end)
    vdfs = VirtualDateFieldActions.list(for_meta: meta)
    all_timestamp_fields = dsfs ++ vdfs

    field_names = for field <- all_timestamp_fields do
      field.name
    end

    query = """
    SELECT "#{Enum.join(field_names, "\", \"")}"
    FROM "#{meta.table_name}";
    """
    {:ok, result} = Ecto.Adapters.SQL.query(Repo, query)

    erl_dates = List.flatten(result.rows)
    datetimes =
      for {{y, m, d}, {h, mm, s, _}} <- erl_dates do
        {:ok, ndt} = NaiveDateTime.from_erl({{y, m, d}, {h, mm, s}})
        {:ok, dt} = DateTime.from_naive(ndt, "Etc/UTC")
        dt
      end
    sorted = Enum.sort(datetimes, fn one, two -> DateTime.compare(one, two) == :gt end)

    upper = List.first(sorted)
    lower = List.last(sorted)

    Plenario.TsTzRange.dump([lower, upper])
  end

  @doc """
  Selects all points in the data set's table and finds the minimum and maximum
  values. From those values, it creates a Polygon.
  """
  @spec compute_bbox!(meta :: Meta) :: Geo.Polygon
  def compute_bbox!(meta) do
    dsfs =
      DataSetFieldActions.list(for_meta: meta)
      |> Enum.filter(fn field -> field.type == "geometry" end)
    vpfs = VirtualPointFieldActions.list(for_meta: meta)
    all_point_fields = dsfs ++ vpfs

    field_names =
      for field <- all_point_fields do
        field.name
      end

    query = """
    SELECT "#{Enum.join(field_names, "\", \"")}"
    FROM "#{meta.table_name}";
    """
    {:ok, result} = Ecto.Adapters.SQL.query(Repo, query)

    points = List.flatten(result.rows)
    xs =
      for pt <- points do
        %{coordinates: {x, _}} = pt
        x
      end
    ys =
      for pt <- points do
        %{coordinates: {_, y}} = pt
        y
      end
    sorted_xs = Enum.sort(xs)
    sorted_ys = Enum.sort(ys)

    max_x = List.first(sorted_xs)
    min_x = List.last(sorted_xs)
    max_y = List.first(sorted_ys)
    min_y = List.last(sorted_ys)

    %Geo.Polygon{coordinates: [[{max_x, min_y}, {min_x, min_y}, {min_x, max_y}, {max_x, max_y}, {max_x, min_y}]], srid: 4326}
  end

  @doc """
  Gets a list of Metas from the database. This can be optionally filtered using
  the opts. See MetaQueries.handle_opts for more details.

  ## Examples

    all_metas = MetaActions.list()
    ready_metas = MetaActions.list(ready_only: true)
    my_erred_metas = MetaActions.list(erred_only: true, for_user: me)
  """
  @spec list(opts :: Keyword.t() | nil) :: list(Meta)
  def list(opts \\ []) do
    MetaQueries.list()
    |> MetaQueries.handle_opts(opts)
    |> Repo.all()
  end

  @doc """
  Gets a single Meta by either their id or slug.

  ## Examples

    meta = MetaActions.get(123)
    meta = MetaActions.get("this-is-a-slug")
    meta = MetaActions.get("this-is-a-slug", with_user: true)
  """
  @spec get(identifier :: integer | String.t(), opts :: Keyword.t()) :: Meta | nil
  def get(identifier, opts \\ []) do
    MetaQueries.get(identifier)
    |> MetaQueries.handle_opts(opts)
    |> Repo.one()
  end

  @doc """
  Gets a list of the field names for a given meta.

  ## Example

    col_names = MetaActions.get_column_names(meta)
  """
  def get_column_names(meta) do
    fields = DataSetFieldActions.list(for_meta: meta)
    field_names = for f <- fields, do: f.name

    field_names
  end
end
