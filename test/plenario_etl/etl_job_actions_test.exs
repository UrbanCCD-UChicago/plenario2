# defmodule PlenarioEtl.Testing.EtlJobActionsTest do
#   use Plenario.Testing.DataCase
#
#   alias PlenarioEtl.Actions.EtlJobActions
#
#   alias Plenario.Actions.{
#     MetaActions,
#     DataSetFieldActions,
#     VirtualPointFieldActions
#   }
#
#   setup %{meta: meta} do
#     {:ok, _} = DataSetFieldActions.create(meta, "id", "text")
#     {:ok, lat} = DataSetFieldActions.create(meta, "lat", "float")
#     {:ok, lon} = DataSetFieldActions.create(meta, "lon", "float")
#     {:ok, _} = DataSetFieldActions.create(meta, "timestamp", "timestamp")
#     {:ok, _} = VirtualPointFieldActions.create(meta, lat.id, lon.id)
#
#     now = DateTime.utc_now()
#     {:ok, meta} = MetaActions.update(meta,
#       refresh_rate: "days",
#       refresh_interval: 1,
#       refresh_starts_on: now
#     )
#     {:ok, meta} = MetaActions.submit_for_approval(meta)
#     {:ok, meta} = MetaActions.approve(meta)
#
#     {:ok, [meta: meta]}
#   end
#
#   test "create", %{meta: meta} do
#     job = EtlJobActions.create!(meta)
#     assert job.state == "new"
#   end
#
#   test "start", %{meta: meta} do
#     assert meta.next_import == nil
#
#     {:ok, job} =
#       EtlJobActions.create!(meta)
#       |> EtlJobActions.start()
#     assert job.state == "running"
#
#     meta = MetaActions.get(meta.id)
#     refute meta.next_import == nil
#   end
#
#   test "mark_succeeded", %{meta: meta} do
#     original_latest_import = meta.latest_import
#
#     {:ok, job} =
#       EtlJobActions.create!(meta)
#       |> EtlJobActions.start()
#
#     {:ok, job} = EtlJobActions.mark_succeeded(job)
#     assert job.state == "succeeded"
#
#     meta = MetaActions.get(meta.id)
#     refute original_latest_import == meta.latest_import
#   end
#
#   test "mark_partial_succeess", %{meta: meta} do
#     original_latest_import = meta.latest_import
#
#     {:ok, job} =
#       EtlJobActions.create!(meta)
#       |> EtlJobActions.start()
#
#     {:ok, job} = EtlJobActions.mark_partial_success(job, [
#       {:error, "something borked"},
#       {:error, "something else borked too"}
#     ])
#     assert job.state == "partial_success"
#
#     meta = MetaActions.get(meta.id)
#     refute original_latest_import == meta.latest_import
#   end
#
#   test "mark_erred", %{meta: meta} do
#     original_latest_import = meta.latest_import
#
#     {:ok, job} =
#       EtlJobActions.create!(meta)
#       |> EtlJobActions.start()
#
#     {:ok, job} = EtlJobActions.mark_erred(job, [
#       {:error, "the whole damn thing just siezed up down the road"}
#     ])
#     assert job.state == "erred"
#
#     meta = MetaActions.get(meta.id)
#     assert original_latest_import == meta.latest_import
#   end
# end
