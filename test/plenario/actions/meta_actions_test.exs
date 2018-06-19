defmodule Plenario.Actions.MetaActionsTest do
  use Plenario.Testing.DataCase

  import Mock

  alias Plenario.Repo

  alias Plenario.Actions.{
    DataSetActions,
    DataSetFieldActions,
    MetaActions,
    VirtualDateFieldActions,
    VirtualPointFieldActions
  }

  defp mock_200(_) do
    %HTTPoison.Response{status_code: 200}
  end

  defp mock_204(_) do
    %HTTPoison.Response{status_code: 204}
  end

  defp mock_non_200(_) do
    %HTTPoison.Response{status_code: 302}
  end

  test "new" do
    changeset = MetaActions.new()

    assert changeset.action == nil
  end

  describe "create" do
    test "with user struct", %{meta: meta} do
      # this is done in data case setup
      assert meta.user_id
      assert meta.table_name
    end

    test "with user id", %{user: user} do
      {:ok, _} = MetaActions.create("a new meta", user.id, "https://example.com/new-meta", "csv")
    end

    test "with a 200 response on the options request", %{user: user} do
      with_mock HTTPoison, options!: &mock_200/1 do
        {:ok, _} = MetaActions.create("a new meta", user.id, "https://example.com/new-meta", "csv")
      end
    end

    test "with a 204 response on the options request", %{user: user} do
      with_mock HTTPoison, options!: &mock_204/1 do
        {:ok, _} = MetaActions.create("a new meta", user.id, "https://example.com/new-meta", "csv")
      end
    end

    test "with a 200 response on the head request", %{user: user} do
      with_mocks([
        {HTTPoison, [], head!: &mock_non_200/1},
        {HTTPoison, [], options!: &mock_200/1}
      ]) do
        {:ok, _} = MetaActions.create("a new meta", user.id, "https://example.com/new-meta", "csv")
      end
    end

    test "with a 204 response on the head request", %{user: user} do
      with_mocks([
        {HTTPoison, [], head!: &mock_non_200/1},
        {HTTPoison, [], options!: &mock_204/1}
      ]) do
        {:ok, _} = MetaActions.create("a new meta", user.id, "https://example.com/new-meta", "csv")
      end
    end

    test "with a non-200 response on either of the requests", %{user: user} do
      with_mocks([
        {HTTPoison, [], head!: &mock_non_200/1},
        {HTTPoison, [], options!: &mock_non_200/1}
      ]) do
        {:error, _} = MetaActions.create("a new meta", user.id, "https://example.com/new-meta", "csv")
      end
    end
  end

  describe "update" do
    test "name", %{meta: meta} do
      new_name = "stuff and nonsense"
      {:ok, _} = MetaActions.update(meta, name: new_name)

      meta = MetaActions.get(meta.id)
      assert meta.name == new_name
    end

    test "source url", %{meta: meta} do
      new_url = "https://example.com/stuff.csv"
      {:ok, _} = MetaActions.update(meta, source_url: new_url)

      meta = MetaActions.get(meta.id)
      assert meta.source_url == new_url
    end

    test "source type", %{meta: meta} do
      new_type = "json"
      {:ok, _} = MetaActions.update(meta, source_type: new_type)

      meta = MetaActions.get(meta.id)
      assert meta.source_type == new_type
    end

    test "description", %{meta: meta} do
      new_descr = "blah blah blah"
      {:ok, _} = MetaActions.update(meta, description: new_descr)

      meta = MetaActions.get(meta.id)
      assert meta.description == new_descr
    end

    test "attribution", %{meta: meta} do
      new_attr = "some city you've never heard of"
      {:ok, _} = MetaActions.update(meta, attribution: new_attr)

      meta = MetaActions.get(meta.id)
      assert meta.attribution == new_attr
    end

    test "refresh rate and interval", %{meta: meta} do
      # bad -- must set interval when setting rate != nil
      new_rr = "years"
      {:error, _} = MetaActions.update(meta, refresh_rate: new_rr)

      # bad -- must set rate when setting interval
      new_int = 1
      {:error, _} = MetaActions.update(meta, refresh_interval: new_int)

      # good
      {:ok, _} = MetaActions.update(meta, refresh_rate: new_rr, refresh_interval: new_int)

      meta = MetaActions.get(meta.id)
      assert meta.refresh_rate == new_rr

      # bad rr value
      {:error, _} = MetaActions.update(meta, refresh_rate: "fortnight")
    end

    test "refresh starts on", %{meta: meta} do
      new_rso = ~D[2018-01-01]
      {:ok, _} = MetaActions.update(meta, refresh_starts_on: new_rso)

      meta = MetaActions.get(meta.id)
      assert meta.refresh_starts_on == new_rso
    end

    test "refresh ends on", %{meta: meta} do
      # bad -- must set rso if setting reo
      new_reo = ~D[2018-01-01]
      {:error, _} = MetaActions.update(meta, refresh_ends_on: new_reo)

      # good
      new_rso = ~D[2017-01-01]
      {:ok, _} = MetaActions.update(meta, refresh_starts_on: new_rso)

      meta = MetaActions.get(meta.id)
      new_reo = ~D[2018-01-01]
      {:ok, _} = MetaActions.update(meta, refresh_ends_on: new_reo)

      # bad -- reo must be later than rso
      new_reo = ~D[2017-01-01]
      new_rso = ~D[2018-01-01]

      meta = MetaActions.get(meta.id)

      {:error, _} = MetaActions.update(meta, refresh_starts_on: new_rso, refresh_ends_on: new_reo)
    end
  end

  test "update_latest_import", %{meta: meta} do
    dt = DateTime.utc_now()
    {:ok, _} = MetaActions.update(meta, latest_import: dt)

    meta = MetaActions.get(meta.id)
    assert meta.latest_import == dt
  end

  test "update_bbox", %{meta: meta} do
    bbox = Geo.WKT.decode("POLYGON ((30 10, 40 40, 20 40, 10 20, 30 10))")
    {:ok, _} = MetaActions.update_bbox(meta, bbox)

    meta = MetaActions.get(meta.id)
    assert meta.bbox == bbox
  end

  test "update_time_range", %{meta: meta} do
    range = Plenario.TsRange.new(~N[2018-01-01 00:00:00], ~N[2019-01-01 00:00:00])
    {:ok, _} = MetaActions.update_time_range(meta, range)
  end

  test "submit_for_approval", %{meta: meta} do
    {:ok, _} = MetaActions.submit_for_approval(meta)

    meta = MetaActions.get(meta.id)
    assert meta.state == "needs_approval"
  end

  test "approve", %{meta: meta} do
    {:ok, m} = MetaActions.submit_for_approval(meta)
    {:ok, _} = MetaActions.approve(m)

    meta = MetaActions.get(meta.id)
    assert meta.state == "awaiting_first_import"
  end

  test "disapprove", %{meta: meta} do
    {:ok, m} = MetaActions.submit_for_approval(meta)
    {:ok, _} = MetaActions.disapprove(m)

    meta = MetaActions.get(meta.id)
    assert meta.state == "new"
  end

  test "mark_first_import", %{meta: meta} do
    {:ok, m} = MetaActions.submit_for_approval(meta)
    {:ok, m} = MetaActions.approve(m)
    {:ok, _} = MetaActions.mark_first_import(m)

    meta = MetaActions.get(meta.id)
    assert meta.state == "ready"
    assert meta.first_import != nil
  end

  test "mark_erred", %{meta: meta} do
    {:ok, m} = MetaActions.submit_for_approval(meta)
    {:ok, m} = MetaActions.approve(m)
    {:ok, m} = MetaActions.mark_first_import(m)
    {:ok, _} = MetaActions.mark_erred(m)

    meta = MetaActions.get(meta.id)
    assert meta.state == "erred"
  end

  test "mark_fixed", %{meta: meta} do
    {:ok, m} = MetaActions.submit_for_approval(meta)
    {:ok, m} = MetaActions.approve(m)
    {:ok, m} = MetaActions.mark_first_import(m)
    {:ok, m} = MetaActions.mark_erred(m)
    {:ok, _} = MetaActions.mark_fixed(m)

    meta = MetaActions.get(meta.id)
    assert meta.state == "ready"
  end

  describe "get" do
    test "with an id", %{meta: meta}  do
      assert MetaActions.get(meta.id)
    end

    test "with a slug", %{meta: meta} do
      assert MetaActions.get(meta.slug)
    end

    test "with opts", %{meta: meta} do
      {:ok, yr} = DataSetFieldActions.create(meta, "year", "integer")
      {:ok, loc} = DataSetFieldActions.create(meta, "location", "text")
      {:ok, _} = VirtualDateFieldActions.create(meta.id, yr.id)
      {:ok, _} = VirtualPointFieldActions.create(meta.id, loc.id)

      meta =
        MetaActions.get(
          meta.id, with_virtual_dates: true, with_virtual_points: true)
      assert length(meta.virtual_dates) == 1
      assert length(meta.virtual_points) == 1
    end
  end

  describe "list" do
    test "vanilla" do
      all_metas = MetaActions.list()
      assert length(all_metas) == 1
    end

    test "new_only" do
      new_metas = MetaActions.list(new_only: true)
      assert length(new_metas) == 1
    end

    test "needs_approval_only" do
      na_metas = MetaActions.list(needs_approval_only: true)
      assert length(na_metas) == 0
    end

    test "awaiting_first_import_only" do
      afi_metas = MetaActions.list(awaiting_first_import_only: true)
      assert length(afi_metas) == 0
    end

    test "ready_only" do
      ready_metas = MetaActions.list(ready_only: true)
      assert length(ready_metas) == 0
    end

    test "erred_only" do
      erred_metas = MetaActions.list(erred_only: true)
      assert length(erred_metas) == 0
    end

    test "with_user", %{user: user} do
      meta =
        MetaActions.list(with_user: true)
        |> List.first()

      assert meta.user.id == user.id
    end

    test "with_fields", %{meta: meta} do
      {:ok, field} = DataSetFieldActions.create(meta, "id", "integer")

      meta =
        MetaActions.list(with_fields: true)
        |> List.first()

      meta_field = List.first(meta.fields)
      assert meta_field.id == field.id
    end

    test "for_user", %{user: user} do
      users_metas = MetaActions.list(for_user: user)
      assert length(users_metas) == 1
    end

    test "ready only and for user", %{user: user} do
      users_ready_metas = MetaActions.list(for_user: user, ready_only: true)
      assert length(users_ready_metas) == 0
    end
  end

  test "compute_time_range!", %{meta: meta} do
    {:ok, _} = DataSetFieldActions.create(meta, "id", "integer")
    {:ok, _} = DataSetFieldActions.create(meta, "observation", "float")
    {:ok, _} = DataSetFieldActions.create(meta, "date", "timestamp")
    {:ok, yr} = DataSetFieldActions.create(meta, "year", "integer")
    {:ok, mo} = DataSetFieldActions.create(meta, "month", "integer")
    {:ok, day} = DataSetFieldActions.create(meta, "day", "integer")
    {:ok, lat} = DataSetFieldActions.create(meta, "lat", "float")
    {:ok, lon} = DataSetFieldActions.create(meta, "lon", "float")
    {:ok, _} = VirtualDateFieldActions.create(meta.id, yr.id, month_field_id: mo.id, day_field_id: day.id)
    {:ok, _} = VirtualPointFieldActions.create(meta.id, lat.id, lon.id)

    DataSetActions.up!(meta)

    insert = """
    INSERT INTO "#{meta.table_name}"
      (id, observation, date, year, month, day, lat, lon)
    VALUES
      (1, 1.1, '2018-01-01 00:00:00', 2017, 1, 1, 10.9, 21.1),
      (2, 1.1, '2018-01-01 00:00:01', 2017, 1, 1, 10.8, 22.2),
      (3, 1.1, '2018-01-01 00:00:10', 2017, 1, 1, 10.7, 23.3),
      (4, 1.1, '2018-01-01 00:01:00', 2017, 1, 1, 10.6, 24.4),
      (5, 1.1, '2019-01-01 00:10:00', 2016, 1, 1, 10.5, 25.5);
    """
    {:ok, _} = Ecto.Adapters.SQL.query(Repo, insert)

    refresh = """
    REFRESH MATERIALIZED VIEW "#{meta.table_name}_view"
    """
    Ecto.Adapters.SQL.query!(Repo, refresh)

    range = MetaActions.compute_time_range!(meta)
    assert range == Plenario.TsRange.new(~N[2016-01-01 00:00:00], ~N[2019-01-01 00:10:00])
  end

  test "compute_bbox!", %{meta: meta} do
    {:ok, _} = DataSetFieldActions.create(meta, "id", "integer")
    {:ok, _} = DataSetFieldActions.create(meta, "observation", "float")
    {:ok, _} = DataSetFieldActions.create(meta, "date", "timestamp")
    {:ok, yr} = DataSetFieldActions.create(meta, "year", "integer")
    {:ok, mo} = DataSetFieldActions.create(meta, "month", "integer")
    {:ok, day} = DataSetFieldActions.create(meta, "day", "integer")
    {:ok, lat} = DataSetFieldActions.create(meta, "lat", "float")
    {:ok, lon} = DataSetFieldActions.create(meta, "lon", "float")
    {:ok, _} = VirtualDateFieldActions.create(meta.id, yr.id, month_field_id: mo.id, day_field_id: day.id)
    {:ok, _} = VirtualPointFieldActions.create(meta.id, lat.id, lon.id)

    DataSetActions.up!(meta)

    insert = """
    INSERT INTO "#{meta.table_name}"
      (id, observation, date, year, month, day, lat, lon)
    VALUES
      (1, 1.1, '2018-01-01 00:00:00', 2017, 1, 1, 10.9, 21.1),
      (2, 1.1, '2018-01-01 00:00:00', 2017, 1, 1, 10.8, 22.2),
      (3, 1.1, '2018-01-01 00:00:00', 2017, 1, 1, 10.7, 23.3),
      (4, 1.1, '2018-01-01 00:00:00', 2017, 1, 1, 10.6, 24.4),
      (5, 1.1, '2019-01-01 00:00:00', 2016, 1, 1, 10.5, 25.5);
    """
    {:ok, _} = Ecto.Adapters.SQL.query(Repo, insert)

    refresh = """
    REFRESH MATERIALIZED VIEW "#{meta.table_name}_view"
    """
    Ecto.Adapters.SQL.query!(Repo, refresh)

    bbox = MetaActions.compute_bbox!(meta)
    assert bbox == %Geo.Polygon{
      coordinates: [
        [{10.9, 21.1}, {10.5, 21.1}, {10.5, 25.5}, {10.9, 25.5}, {10.9, 21.1}]
      ],
      srid: 4326
    }
  end

  # todo(heyzoos) If I mock up! I also have to mock down? Investigate.
  # todo(heyzoos) Add a test to make sure down! cleans up properly.
  test "approve/1 with failing call to `up!/1`", %{meta: meta} do
    with_mock(DataSetActions,
      up!: fn _ -> raise(Postgrex.Error, message: "Intentional Postgres.Error") end,
      down!: fn _ -> :ok end
    ) do
      MetaActions.submit_for_approval(meta)
      meta = MetaActions.get(meta.id())
      MetaActions.approve(meta)
      meta = MetaActions.get(meta.id())
      assert meta.state == "erred"
    end
  end

  test "dump_bbox/1 returns properly formatted string", %{meta: meta} do
    assert MetaActions.dump_bbox(meta) == nil
    meta = %{meta | bbox: %Geo.Polygon{coordinates: [[{0, 0}, {1, 0}]]}}
    assert MetaActions.dump_bbox(meta) == "[[0,0], [1,0]]"
  end
end
