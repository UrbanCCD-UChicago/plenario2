defmodule Plenario.Testing.DataSetActionsTest do
  use Plenario.Testing.DataCase

  import Mock

  alias Geo.{
    Polygon,
    Point
  }

  alias Plenario.{
    DataSetActions,
    FieldActions,
    TsRange,
    VirtualDateActions,
    VirtualPointActions
  }

  defp mock_404(_), do: %HTTPoison.Response{status_code: 404}

  describe "list" do
    @tag :user
    @tag :data_set
    test "all of them" do
      data_sets = DataSetActions.list()
      assert length(data_sets) == 1
    end

    @tag :user
    @tag :data_set
    test "with_user" do
      DataSetActions.list()
      |> Enum.each(& refute Ecto.assoc_loaded?(&1.user))

      DataSetActions.list(with_user: true)
      |> Enum.each(& assert Ecto.assoc_loaded?(&1.user))
    end

    @tag :user
    @tag :data_set
    test "with_fields" do
      DataSetActions.list()
      |> Enum.each(& refute Ecto.assoc_loaded?(&1.fields))

      DataSetActions.list(with_fields: true)
      |> Enum.each(& assert Ecto.assoc_loaded?(&1.fields))
    end

    @tag :user
    @tag :data_set
    test "with_virtual_dates" do
      DataSetActions.list()
      |> Enum.each(& refute Ecto.assoc_loaded?(&1.virtual_dates))

      DataSetActions.list(with_virtual_dates: true)
      |> Enum.each(& assert Ecto.assoc_loaded?(&1.virtual_dates))
    end

    @tag :user
    @tag :data_set
    test "with_virtual_points" do
      DataSetActions.list()
      |> Enum.each(& refute Ecto.assoc_loaded?(&1.virtual_points))

      DataSetActions.list(with_virtual_points: true)
      |> Enum.each(& assert Ecto.assoc_loaded?(&1.virtual_points))
    end

    @tag :user
    @tag :data_set
    test "state", %{data_set: ds} do
      {:ok, _} =
        {:ok, _} = DataSetActions.update(ds, state: "awaiting_approval")

      new = DataSetActions.list(state: "new")
      assert length(new) == 0

      waiting = DataSetActions.list(state: "awaiting_approval")
      assert length(waiting) == 1
    end

    @tag :user
    @tag :data_set
    test "for_user", %{user: user} do
      data_sets = DataSetActions.list(for_user: user)
      assert length(data_sets) == 1

      other = create_user(%{}, username: "Another User", email: "another@example.com", password: "password")

      data_sets = DataSetActions.list(for_user: other)
      assert length(data_sets) == 0
    end

    @tag :user
    @tag :data_set
    test "bbox_contains", %{data_set: ds} do
      bbox = %Polygon{
        srid: 4326,
        coordinates: [[
          {0, 0},
          {0, 100},
          {100, 100},
          {100, 0},
          {0, 0}
        ]]
      }

      {:ok, _} = DataSetActions.update(ds, bbox: bbox)

      point = %Point{
        srid: 4326,
        coordinates: {10, 42}
      }

      data_sets = DataSetActions.list(bbox_contains: point)
      assert length(data_sets) == 1

      point = %Point{
        srid: 4326,
        coordinates: {-10, 42}
      }

      data_sets = DataSetActions.list(bbox_contains: point)
      assert length(data_sets) == 0
    end

    @tag :user
    @tag :data_set
    test "bbox_intersects", %{data_set: ds} do
      bbox = %Polygon{
        srid: 4326,
        coordinates: [[
          {0, 0},
          {0, 100},
          {100, 100},
          {100, 0},
          {0, 0}
        ]]
      }

      {:ok, _} = DataSetActions.update(ds, bbox: bbox)

      poly = %Polygon{
        srid: 4326,
        coordinates: [[
          {50, 50},
          {50, 150},
          {150, 150},
          {150, 50},
          {50, 50}
        ]]
      }

      data_sets = DataSetActions.list(bbox_intersects: poly)
      assert length(data_sets) == 1

      poly = %Polygon{
        srid: 4326,
        coordinates: [[
          {-50, -50},
          {-50, -150},
          {-150, -150},
          {-150, -50},
          {-50, -50}
        ]]
      }

      data_sets = DataSetActions.list(bbox_intersects: poly)
      assert length(data_sets) == 0
    end

    @tag :user
    @tag :data_set
    test "time_range_contains", %{data_set: ds} do
      time_range = TsRange.new(~N[2018-01-01 00:00:00], ~N[2019-01-01 00:00:00], true, false)

      {:ok, _} = DataSetActions.update(ds, time_range: time_range)

      timestamp = ~N[2018-04-21 15:00:00]

      data_sets = DataSetActions.list(time_range_contains: timestamp)
      assert length(data_sets) == 1

      timestamp = ~N[2019-04-21 15:00:00]

      data_sets = DataSetActions.list(time_range_contains: timestamp)
      assert length(data_sets) == 0
    end

    @tag :user
    @tag :data_set
    test "time_range_intersects", %{data_set: ds} do
      time_range = TsRange.new(~N[2018-01-01 00:00:00], ~N[2019-01-01 00:00:00], true, false)

      {:ok, _} = DataSetActions.update(ds, time_range: time_range)

      tsrange = TsRange.new(~N[2018-04-21 15:00:00], ~N[2018-04-22 02:00:00], true, false)

      data_sets = DataSetActions.list(time_range_intersects: tsrange)
      assert length(data_sets) == 1

      tsrange = TsRange.new(~N[2019-04-21 15:00:00], ~N[2019-04-22 02:00:00], true, false)

      data_sets = DataSetActions.list(time_range_intersects: tsrange)
      assert length(data_sets) == 0
    end
  end

  describe "get" do
    @tag :user
    @tag :data_set
    test "with a known id", %{data_set: ds} do
      {:ok, _} = DataSetActions.get(ds.id)
    end

    @tag :user
    @tag :data_set
    test "with a known slug", %{data_set: ds} do
      {:ok, _} = DataSetActions.get(ds.slug)
    end

    test "with an unknown id" do
      {:error, nil} = DataSetActions.get(123456789)
    end

    test "with an unknown slug" do
      {:error, nil} = DataSetActions.get("12345678-nine")
    end
  end

  describe "get!" do
    @tag :user
    @tag :data_set
    test "with a known id", %{data_set: ds} do
      DataSetActions.get!(ds.id)
    end

    @tag :user
    @tag :data_set
    test "with a known slug", %{data_set: ds} do
      DataSetActions.get!(ds.slug)
    end

    test "with an unknown id" do
      assert_raise Ecto.NoResultsError, fn ->
        DataSetActions.get!(123456789)
      end
    end

    test "with an unknown slug" do
      assert_raise Ecto.NoResultsError, fn ->
        DataSetActions.get!("12345678-nine")
      end
    end
  end

  describe "create" do
    @tag :user
    test "sets the slug", %{user: user} do
      {:ok, ds} = DataSetActions.create name: "Some Data Set",
        user: user,
        src_url: "https://example.com",
        src_type: "csv",
        socrata?: false

      assert ds.slug == "some-data-set"
    end

    @tag :user
    test "sets the table_name", %{user: user} do
      {:ok, ds} = DataSetActions.create name: "Some Data Set",
        user: user,
        src_url: "https://example.com",
        src_type: "csv",
        socrata?: false

      assert ds.table_name == "some_data_set"
    end

    @tag :user
    test "sets the view_name", %{user: user} do
      {:ok, ds} = DataSetActions.create name: "Some Data Set",
        user: user,
        src_url: "https://example.com",
        src_type: "csv",
        socrata?: false

      assert ds.view_name == "some_data_set_view"
    end

    @tag :user
    test "name too long", %{user: user} do
      name = Enum.reduce(1..60, "", fn i, acc -> "#{acc}#{i}" end)

      {:error, changeset} = DataSetActions.create name: name,
        user: user,
        src_url: "https://example.com",
        src_type: "csv",
        socrata?: false

      assert "should be at most 58 character(s)" in errors_on(changeset).name
    end

    @tag :user
    test "invalid source type", %{user: user} do
      {:error, changeset} = DataSetActions.create name: "Test DS",
        user: user,
        src_url: "https://example.com",
        src_type: "fancy art",
        socrata?: false

      assert "is invalid" in errors_on(changeset).src_type
    end

    @tag :user
    test "invalid refresh interval", %{user: user} do
      {:error, changeset} = DataSetActions.create name: "Test DS",
        user: user,
        src_url: "https://example.com",
        src_type: "csv",
        refresh_interval: "microseconds",
        socrata?: false

      assert "is invalid" in errors_on(changeset).refresh_interval
    end

    @tag :user
    test "invalid refresh rate", %{user: user} do
      {:error, changeset} = DataSetActions.create name: "Test DS",
        user: user,
        src_url: "https://example.com",
        src_type: "csv",
        refresh_rate: -1,
        socrata?: false

      assert "must be greater than 0" in errors_on(changeset).refresh_rate
    end

    @tag :user
    test "malformed socrata 4x4", %{user: user} do
      {:error, changeset} = DataSetActions.create name: "Test DS",
        user: user,
        src_type: "csv",
        soc_domain: "data.cityofchicago.org",
        soc_4x4: "123-abc",
        socrata?: false

      assert "has invalid format" in errors_on(changeset).soc_4x4
    end

    @tag :user
    test "src and socrata sources given", %{user: user} do
      {:error, changeset} = DataSetActions.create name: "Test DS",
        user: user,
        src_type: "csv",
        soc_domain: "data.cityofchicago.org",
        soc_4x4: "1234-abcd",
        src_url: "https://example.com",
        socrata?: true

      assert "cannot set both web resource and Socrata resource information -- they are mutually exclusive" in errors_on(changeset).soc_domain
      assert "cannot set both web resource and Socrata resource information -- they are mutually exclusive" in errors_on(changeset).soc_4x4
      assert "cannot set both web resource and Socrata resource information -- they are mutually exclusive" in errors_on(changeset).src_url
    end

    @tag :user
    test "unreachable src url", %{user: user} do
      with_mocks [
        {HTTPoison, [], options!: &mock_404/1},
        {HTTPoison, [], head!: &mock_404/1}
      ] do
        {:error, changeset} = DataSetActions.create name: "Test DS",
          user: user,
          src_url: "https://example.com",
          src_type: "csv",
        socrata?: false

        assert "cannot resolve given route information" in errors_on(changeset).src_url
      end
    end

    @tag :user
    test "unreachable socrata attrs", %{user: user} do
      {:error, changeset} = DataSetActions.create name: "Test DS",
        user: user,
        src_type: "csv",
        soc_domain: "data.cityofchicago.org",
        soc_4x4: "1234-5678",
        socrata?: true

      assert "cannot resolve given route information" in errors_on(changeset).soc_4x4
      assert "cannot resolve given route information" in errors_on(changeset).soc_domain
    end

    @tag :user
    test "taken name", %{user: user} do
      {:ok, ds} = DataSetActions.create name: "Test DS",
        user: user,
        src_url: "https://example.com",
        src_type: "csv",
        socrata?: false

      {:error, changeset} = DataSetActions.create name: ds.name,
        user: user,
        src_url: "https://example.com/a",
        src_type: "csv",
        socrata?: false

      assert "has already been taken" in errors_on(changeset).name
    end

    @tag :user
    test "taken source url", %{user: user} do
      {:ok, ds} = DataSetActions.create name: "Test DS",
        user: user,
        src_url: "https://example.com",
        src_type: "csv",
        socrata?: false

      {:error, changeset} = DataSetActions.create name: "Another DS",
        user: user,
        src_url: ds.src_url,
        src_type: "csv",
        socrata?: false

      assert "has already been taken" in errors_on(changeset).src_url
    end

    @tag :user
    test "taken socrata attrs", %{user: user} do
      {:ok, ds} = DataSetActions.create name: "Test DS",
        user: user,
        src_type: "csv",
        soc_domain: "data.cityofchicago.org",
        soc_4x4: "6zsd-86xi",
        socrata?: true

      {:error, changeset} = DataSetActions.create name: "Another DS",
        user: user,
        src_type: "csv",
        soc_domain: ds.soc_domain,
        soc_4x4: ds.soc_4x4,
        socrata?: true

      assert "has already been taken" in errors_on(changeset).soc_4x4
    end
  end

  describe "update" do
    @tag :user
    @tag :data_set
    test "change the name", %{data_set: ds} do
      {:ok, updated} = DataSetActions.update(ds, name: "A Better Name")

      assert updated.slug == "a-better-name"
      assert updated.table_name == "a_better_name"
      assert updated.view_name == "a_better_name_view"
    end

    @tag :user
    @tag :data_set
    test "change the name when no longer new", %{data_set: ds} do
      {:ok, _} = DataSetActions.update(ds, state: "awaiting_approval")
      ds = DataSetActions.get! ds.id

      {:error, changeset} = DataSetActions.update(ds, name: "Not Gonna Happen")
      assert "cannot make selected changes after state is no longer new" in errors_on(changeset).name
    end

    @tag :user
    @tag :data_set
    test "invalid state", %{data_set: ds} do
      {:error, changeset} = DataSetActions.update(ds, state: "busted")
      assert "is invalid" in errors_on(changeset).state
    end
  end

  describe "delete" do
    @tag :user
    @tag :data_set
    test "should delete all subordinate fields", %{data_set: ds} do
      {:ok, _} = FieldActions.create data_set: ds,
        name: "Some Field",
        type: "text"

      fields = FieldActions.list(for_data_set: ds)
      assert length(fields) > 0

      {:ok, _} = DataSetActions.delete ds

      fields = FieldActions.list(for_data_set: ds)
      assert length(fields) == 0
    end

    @tag :user
    @tag :data_set
    test "should delete all subordinate virtual_dates", %{data_set: ds} do
      {:ok, f} = FieldActions.create data_set: ds,
        name: "Some Field",
        type: "text"

      {:ok, _} = VirtualDateActions.create data_set: ds, yr_field: f

      fields = VirtualDateActions.list(for_data_set: ds)
      assert length(fields) > 0

      {:ok, _} = DataSetActions.delete ds

      fields = VirtualDateActions.list(for_data_set: ds)
      assert length(fields) == 0
    end

    @tag :user
    @tag :data_set
    test "should delete all subordinate virtual_points", %{data_set: ds} do
      {:ok, f} = FieldActions.create data_set: ds,
        name: "Some Field",
        type: "text"

      {:ok, _} = VirtualPointActions.create data_set: ds, loc_field: f

      fields = VirtualPointActions.list(for_data_set: ds)
      assert length(fields) > 0

      {:ok, _} = DataSetActions.delete ds

      fields = VirtualPointActions.list(for_data_set: ds)
      assert length(fields) == 0
    end
  end

  describe "compute_next_import!" do
    @tag :user
    @tag data_set: [refresh_rate: 1, refresh_interval: "days"]
    test "should return a timestamp", %{data_set: ds} do
      now = NaiveDateTime.utc_now()
      next = DataSetActions.compute_next_import!(ds, now)

      expected = Timex.shift(now, days: 1)

      assert next == expected
    end

    @tag :user
    @tag data_set: [refresh_interval: "days"]
    test "when refresh_rate is nil it should return nil", %{data_set: ds} do
      assert DataSetActions.compute_next_import!(ds, NaiveDateTime.utc_now()) == nil
    end

    @tag :user
    @tag data_set: [refresh_rate: 1]
    test "when refresh_interval is nil it should return nil", %{data_set: ds} do
      assert DataSetActions.compute_next_import!(ds, NaiveDateTime.utc_now()) == nil
    end
  end

  describe "compute_bbox!" do
    setup do
      user = create_user(%{})
      data_set = create_data_set(%{user: user})
      _ = create_field(%{data_set: data_set}, name: "id", type: "text")
      _ = create_field(%{data_set: data_set}, name: "location", type: "geometry")

      Repo.up!(data_set)

      {:ok, data_set: data_set}
    end

    test "should return a polygon", %{data_set: ds} do
      :ok = Repo.etl!(ds, "test/fixtures/id_location.csv")
      bbox = DataSetActions.compute_bbox!(ds)

      expected = %Polygon{
        srid: 4326,
        coordinates: [[
          {1, 1},
          {1, 2},
          {2, 2},
          {2, 1},
          {1, 1}
        ]]
      }

      assert bbox == expected
    end

    test "when there isn't any data it should return nil", %{data_set: ds} do
      assert is_nil DataSetActions.compute_bbox!(ds)
    end
  end

  describe "compute_hull!" do
    setup do
      user = create_user(%{})
      data_set = create_data_set(%{user: user})
      _ = create_field(%{data_set: data_set}, name: "id", type: "text")
      _ = create_field(%{data_set: data_set}, name: "location", type: "geometry")

      Repo.up!(data_set)

      {:ok, data_set: data_set}
    end

    test "should return a polygon", %{data_set: ds} do
      :ok = Repo.etl!(ds, "test/fixtures/id_location.csv")
      hull = DataSetActions.compute_hull!(ds)

      expected = %Polygon{
        srid: 4326,
        coordinates: [[
          {1, 1},
          {1, 2},
          {2, 2},
          {2, 1},
          {1, 1}
        ]]
      }

      assert hull == expected
    end

    test "when there isn't any data it should return nil", %{data_set: ds} do
      assert is_nil DataSetActions.compute_hull!(ds)
    end
  end

  describe "compute_time_range!" do
    setup do
      user = create_user(%{})
      data_set = create_data_set(%{user: user})
      _ = create_field(%{data_set: data_set}, name: "id", type: "text")
      _ = create_field(%{data_set: data_set}, name: "timestamp", type: "timestamp")

      Repo.up!(data_set)

      {:ok, data_set: data_set}
    end

    test "should return a tsrange", %{data_set: ds} do
      :ok = Repo.etl!(ds, "test/fixtures/id_timestamp.csv")
      range = DataSetActions.compute_time_range!(ds)

      expected = %Plenario.TsRange{
        lower: ~N[2018-01-01 00:00:00.000000],
        upper: ~N[2019-01-01 00:00:00.000000]
      }

      assert range == expected
    end

    test "when there isn't any data it should return nil", %{data_set: ds} do
      assert is_nil DataSetActions.compute_time_range!(ds)
    end
  end

  describe "get_num_records!" do
    setup do
      user = create_user(%{})
      data_set = create_data_set(%{user: user})
      _ = create_field(%{data_set: data_set}, name: "id", type: "text")
      _ = create_field(%{data_set: data_set}, name: "timestamp", type: "timestamp")

      Repo.up!(data_set)

      {:ok, data_set: data_set}
    end

    test "should return an integer", %{data_set: ds} do
      :ok = Repo.etl!(ds, "test/fixtures/id_timestamp.csv")
      count = DataSetActions.get_num_records!(ds)

      assert count == 4
    end

    test "when there isn't any data it should return nil", %{data_set: ds} do
      assert is_nil DataSetActions.get_num_records!(ds)
    end
  end
end
