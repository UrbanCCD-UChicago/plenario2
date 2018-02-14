defmodule PlenarioWeb.Admin.MetaController do
  use PlenarioWeb, :admin_controller

  alias Plenario.Actions.{
    MetaActions,
    DataSetFieldActions,
    UniqueConstraintActions,
    VirtualDateFieldActions,
    VirtualPointFieldActions
  }

  def index(conn, _) do
    all_metas = MetaActions.list(with_user: true)
    erred_metas = Enum.filter(all_metas, fn m -> m.state == "erred" end)
    ready_metas = Enum.filter(all_metas, fn m -> m.state == "ready" end)
    awaiting_first_import_metas = Enum.filter(all_metas, fn m -> m.state == "awaiting_first_import" end)
    needs_approval_metas = Enum.filter(all_metas, fn m -> m.state == "needs_approval" end)
    new_metas = Enum.filter(all_metas, fn m -> m.state == "new" end)

    num_erred = length(erred_metas)
    num_ready = length(ready_metas)
    num_afi = length(awaiting_first_import_metas)
    num_na = length(needs_approval_metas)
    num_new = length(new_metas)

    chart_kvs = [
      {"Erred", num_erred},
      {"Ready", num_ready},
      {"Awaiting First Import", num_afi},
      {"Needs Approval", num_na},
      {"New", num_new}
    ]

    render(conn, "index.html", all_metas: all_metas, erred_metas: erred_metas,
      ready_metas: ready_metas, awaiting_first_import_metas: awaiting_first_import_metas,
      needs_approval_metas: needs_approval_metas, new_metas: new_metas,
      num_erred: num_erred, num_ready: num_ready, num_afi: num_afi,
      num_na: num_na, num_new: num_new, chart_kvs: chart_kvs)
  end

  def review(conn, %{"id" => id}) do
    meta = MetaActions.get(id, with_user: true)
    fields = DataSetFieldActions.list(for_meta: meta)
    constraints = UniqueConstraintActions.list(for_meta: meta)
    virtual_dates = VirtualDateFieldActions.list(for_meta: meta, with_fields: true)
    virtual_points = VirtualPointFieldActions.list(for_meta: meta, with_fields: true)

    render(conn, "review.html", meta: meta, fields: fields,
      constraints: constraints, virtual_dates: virtual_dates,
      virtual_points: virtual_points)
  end

  def approve(conn, %{"id" => id}) do
    meta = MetaActions.get(id)
    case MetaActions.approve(meta) do
      {:ok, meta} ->
        conn
        |> put_flash(:success, "Meta #{meta.name} approved.")
        |> redirect(to: meta_path(conn, :index))

      {:error, _} ->
        conn
        |> put_flash(:error, "Something went wrong when approving meta #{meta}")
        |> redirect(to: meta_path(conn, :index))
    end
  end

  def disapprove(conn, %{"id" => id}) do
    meta = MetaActions.get(id)
    case MetaActions.disapprove(meta) do
      {:ok, meta} ->
        conn
        |> put_flash(:success, "Meta #{meta.name} disapproved.")
        |> redirect(to: meta_path(conn, :index))

      {:error, _} ->
        conn
        |> put_flash(:error, "Something went wrong when disapproving meta #{meta}")
        |> redirect(to: meta_path(conn, :index))
    end
  end
end
