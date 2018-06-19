defmodule Plenario.Testing.PlenarioTest do
  use Plenario.Testing.DataCase

  alias Plenario

  alias Plenario.Repo

  alias Plenario.Actions.MetaActions

  alias Plenario.Schemas.Meta

  setup %{user: user, meta: meta} do
    # add bbox and range to original meta, make ready
    bbox = Geo.WKT.decode("POLYGON ((30 10, 40 40, 20 40, 10 20, 30 10))")
    {:ok, _} = MetaActions.update_bbox(meta, bbox)
    {:ok, _} = MetaActions.update_time_range(meta, Plenario.TsRange.new(~N[2017-01-01T00:00:00], ~N[2018-12-31T00:00:00]))
    m = MetaActions.get(meta.id)
    Meta.submit_for_approval(m) |> Repo.update()
    m = MetaActions.get(meta.id)
    Meta.approve(m) |> Repo.update()
    m = MetaActions.get(meta.id)
    Meta.mark_first_import(m) |> Repo.update()

    # create another meta and make ready
    {:ok, m} = MetaActions.create("test 2", user, "https://example.com/2", "csv")
    meta2 = MetaActions.get(m.id)
    bbox = Geo.WKT.decode("POLYGON ((-30 -10, -40 -40, -20 -40, -10 -20, -30 -10))")
    {:ok, _} = MetaActions.update_bbox(meta2, bbox)
    {:ok, _} = MetaActions.update_time_range(meta2, Plenario.TsRange.new(~N[2015-01-01T00:00:00], ~N[2016-12-31T00:00:00]))
    m = MetaActions.get(meta2.id)
    Meta.submit_for_approval(m) |> Repo.update()
    m = MetaActions.get(meta2.id)
    Meta.approve(m) |> Repo.update()
    m = MetaActions.get(meta2.id)
    Meta.mark_first_import(m) |> Repo.update()

    # add them back to the context
    meta = MetaActions.get(meta.id)
    meta2 = MetaActions.get(meta2.id)
    {:ok, [meta: meta, meta2: meta2]}
  end

  describe "search_data_sets" do
    test "with bbox", %{meta: meta} do
      # with results

      bbox = Geo.WKT.decode("POLYGON ((30 20, 40 50, 10 30, 30 20))")
      results = Plenario.search_data_sets(bbox)
      assert length(results) == 1

      result = List.first(results)
      assert result.id == meta.id

      # no results

      bbox = Geo.WKT.decode("POLYGON ((3 2, 4 5, 1 3, 3 2))")
      results = Plenario.search_data_sets(bbox)
      assert length(results) == 0
    end

    test "with bbox and time range", %{meta2: meta2} do
      # with results

      bbox = Geo.WKT.decode("POLYGON ((-30 -20, -40 -50, -10 -30, -30 -20))")
      lower = ~N[2014-11-01T00:00:00]
      upper = ~N[2015-11-01T00:00:00]
      range = Plenario.TsRange.new(lower, upper)
      results = Plenario.search_data_sets(bbox, range)
      assert length(results) == 1

      result = List.first(results)
      assert result.id == meta2.id

      # no results
      bbox = Geo.WKT.decode("POLYGON ((30 20, 40 50, 10 30, 30 20))")
      results = Plenario.search_data_sets(bbox, range)
      assert length(results) == 0
    end
  end
end
