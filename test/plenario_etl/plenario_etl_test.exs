defmodule PlenarioEtl.Testing.PlenarioEtlTest do
  use Plenario.Testing.EtlCase

  alias Plenario.Actions.MetaActions

  alias PlenarioEtl

  describe "PlenarioEtl.find_data_sets/0" do
    test "data set has valid refresh dates and is awaiting first import", %{meta: meta} do
      {:ok, _} = MetaActions.update(meta, refresh_starts_on: ~N[1999-12-31 23:59:59])
      meta = MetaActions.get(meta.id)
      {:ok, _} = MetaActions.submit_for_approval(meta)
      meta = MetaActions.get(meta.id)
      {:ok, _} = MetaActions.approve(meta)

      metas = PlenarioEtl.find_data_sets() |> Enum.map(& &1.id)
      assert metas == [meta.id]
    end

    test "data set has valid refresh dates but is awaiting approval", %{meta: meta} do
      {:ok, _} = MetaActions.update(meta, refresh_starts_on: ~N[1999-12-31 23:59:59])
      meta = MetaActions.get(meta.id)
      {:ok, _} = MetaActions.submit_for_approval(meta)

      assert PlenarioEtl.find_data_sets() == []
    end

    test "data set is ready and has valid refresh dates and the next import is in the past", %{meta: meta} do
      {:ok, _} = MetaActions.update(meta, refresh_starts_on: ~N[1999-12-31 23:59:59], refresh_ends_on: ~N[2999-12-31 23:59:59])
      meta = MetaActions.get(meta.id)
      {:ok, _} = MetaActions.submit_for_approval(meta)
      meta = MetaActions.get(meta.id)
      {:ok, _} = MetaActions.approve(meta)
      meta = MetaActions.get(meta.id)
      {:ok, _} = MetaActions.mark_first_import(meta)
      meta = MetaActions.get(meta.id)
      {:ok, _} = MetaActions.update(meta, next_import: ~N[2000-12-31 23:59:59])

      metas = PlenarioEtl.find_data_sets() |> Enum.map(& &1.id)
      assert metas == [meta.id]
    end

    test "data set has valid refresh dates and is awaiting first import but starts in the future", %{meta: meta} do
      {:ok, _} = MetaActions.update(meta, refresh_starts_on: ~N[2999-12-31 23:59:59])
      meta = MetaActions.get(meta.id)
      {:ok, _} = MetaActions.submit_for_approval(meta)
      meta = MetaActions.get(meta.id)
      {:ok, _} = MetaActions.approve(meta)

      assert PlenarioEtl.find_data_sets() == []
    end

    test "data set is ready, but refresh ended in the past", %{meta: meta} do
      {:ok, _} = MetaActions.update(meta, refresh_starts_on: ~N[1999-12-31 23:59:59], refresh_ends_on: ~N[2000-12-31 23:59:59])
      meta = MetaActions.get(meta.id)
      {:ok, _} = MetaActions.submit_for_approval(meta)
      meta = MetaActions.get(meta.id)
      {:ok, _} = MetaActions.approve(meta)
      meta = MetaActions.get(meta.id)
      {:ok, _} = MetaActions.mark_first_import(meta)

      assert PlenarioEtl.find_data_sets() == []
    end
  end
end
