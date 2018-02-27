defmodule PlenarioWeb.Web.DataSetController do
  use PlenarioWeb, :web_controller

  alias Plenario.Actions.{
    DataSetFieldActions,
    MetaActions,
    VirtualDateFieldActions,
    VirtualPointFieldActions
  }

  alias Plenario.Schemas.Meta

  alias PlenarioWeb.Web.ControllerUtils

  plug :authorize_resource, model: Meta

  def show(conn, %{"id" => id}) do
    meta = MetaActions.get(id, with_user: true, with_fields: true, with_constraints: true)
    do_show(meta, conn)
  end

  defp do_show(nil, conn), do: do_404(conn)
  defp do_show(%Meta{} = meta, conn) do
    user = Guardian.Plug.current_resource(conn)
    virtual_dates = VirtualDateFieldActions.list(for_meta: meta, with_fields: true)
    virtual_points = VirtualPointFieldActions.list(for_meta: meta, with_fields: true)
    disabled? = meta.state != "new"
    user_is_owner? =
      case user do
        nil -> false
        _ -> user.id == meta.user_id
      end

    render(conn, "show.html",
      meta: meta,
      virtual_dates: virtual_dates,
      virtual_points: virtual_points,
      disabled?: disabled?,
      user_is_owner?: user_is_owner?
    )
  end

  def new(conn, _) do
    changeset = MetaActions.new()
    action = data_set_path(conn, :create)
    type_choices = Meta.get_source_type_choices()
    render(conn, "create.html", changeset: changeset, action: action, type_choices: type_choices)
  end

  def create(conn, %{"meta" => %{"name" => name, "user_id" => user_id, "source_url" => source_url, "source_type" => source_type}}) do
    case MetaActions.create(name, user_id, source_url, source_type) do
      {:ok, meta} ->
        field_types = MetaActions.guess_field_types!(meta)
        for {name, type} <- field_types, do: DataSetFieldActions.create(meta, "#{name}", type)

        conn
        |> put_flash(:success, "Created data set #{meta.name}")
        |> redirect(to: data_set_path(conn, :show, meta.id))

      {:error, changeset} ->
        action = data_set_path(conn, :create)
        type_choices = Meta.get_source_type_choices()
        conn
        |> put_status(:bad_request)
        |> put_flash(:error, "Please review errors below.")
        |> render("create.html", changeset: changeset, action: action, type_choices: type_choices)
    end
  end

  def edit(conn, %{"id" => id}) do
    meta = MetaActions.get(id,
      with_user: true, with_fields: true, with_constraints: true,
      with_virtual_dates: true, with_virtual_points: true
    )
    do_edit(meta, id, conn)
  end

  defp do_edit(nil, _, conn), do: do_404(conn)
  defp do_edit(%Meta{} = meta, id, conn) do
    changeset = MetaActions.edit(meta)
    action = data_set_path(conn, :update, id)

    source_type_choices = Meta.get_source_type_choices()
    refresh_rate_choices = Meta.get_refresh_rate_choices()

    render(conn, "edit.html", meta: meta, changeset: changeset, action: action,
      source_type_choices: source_type_choices,
      refresh_rate_choices: refresh_rate_choices)
  end

  def update(conn, %{"id" => id, "meta" => %{"force_fields_reset" => force_fields_reset}} = params) do
    meta = MetaActions.get(id)
    do_update(meta, id, force_fields_reset, params, conn)
  end

  defp do_update(nil, _, _, _, conn), do: do_404(conn)
  defp do_update(%Meta{} = meta, id, force_fields_reset, params, conn) do
    update_params = Map.get(params, "meta")
    original_source = meta.source_url
    updated_source = Map.get(update_params, "source_url")
    reset_fields = original_source != updated_source
    force_fields_reset = force_fields_reset == "true"

    update_params = Enum.into(update_params, [])
    case MetaActions.update(meta, update_params) do
      {:ok, meta} ->
        if reset_fields or force_fields_reset do
          try do
            field_types = MetaActions.guess_field_types!(meta)
            fields = DataSetFieldActions.list(for_meta: meta)
            for f <- fields, do: DataSetFieldActions.delete(f)
            for {name, type} <- field_types, do: DataSetFieldActions.create(meta, "#{name}", type)
          rescue
            _ -> put_flash(conn, :warning, "We couldn't parse the document to generate field definitions.")
          end
        end

        conn
        |> put_flash(:success, "Successfully updated #{meta.name}!")
        |> redirect(to: data_set_path(conn, :show, id))

      {:error, changeset} ->
        action = data_set_path(conn, :update, id)
        source_type_choices = Meta.get_source_type_choices()
        refresh_rate_choices = Meta.get_refresh_rate_choices()

        conn
        |> put_status(:bad_request)
        |> put_flash(:error, "Please review errors below.")
        |> ControllerUtils.flash_base_errors(changeset)
        |> render(
          "edit.html", meta: meta, changeset: changeset, action: action,
          source_type_choices: source_type_choices,
          refresh_rate_choices: refresh_rate_choices
        )
    end
  end

  def submit_for_approval(conn, %{"id" => id}) do
    meta = MetaActions.get(id)
    do_submit_for_approval(meta, id, conn)
  end

  defp do_submit_for_approval(nil, _, conn), do: do_404(conn)
  defp do_submit_for_approval(%Meta{} = meta, id, conn) do
    case MetaActions.submit_for_approval(meta) do
      {:ok, _} ->
        conn
        |> put_flash(:success, "#{meta.name} submitted for approval.")
        |> redirect(to: data_set_path(conn, :show, id))

      {:error, _} ->
        conn
        |> put_flash(:error, "Something went wrong submitting this for approval.")
        |> redirect(to: data_set_path(conn, :show, id))
    end
  end

  def ingest_now(conn, %{"id" => id}) do
    meta = MetaActions.get(id)
    do_ingest_now(meta, id, conn)
  end

  defp do_ingest_now(nil, _, conn), do: do_404(conn)
  defp do_ingest_now(%Meta{} = meta, id, conn) do
    case Enum.member?(["awaiting_first_import", "ready", "erred"], meta.state) do
      true ->
        PlenarioEtl.Worker.async_load!(id)
        conn
        |> put_flash(:success, "Begining ingest process")
        |> redirect(to: data_set_path(conn, :show, id))

      false ->
        conn
        |> put_flash(:error, "Cannot ingest at this time")
        |> redirect(to: data_set_path(conn, :show, id))
    end
  end
end
