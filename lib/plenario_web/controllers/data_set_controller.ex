defmodule PlenarioWeb.DataSetController do
  use PlenarioWeb, :controller

  require Logger

  alias Plenario.{
    Auth.Guardian,
    DataSet,
    DataSetActions,
    Etl,
    FieldActions,
    VirtualDateActions,
    VirtualPointActions
  }

  plug :authorize_resource, model: DataSet

  # CRUD

  def new(conn, %{"name" => name, "socrata" => soc?}) do
    soc? = if soc? == "true", do: true, else: false

    changeset = DataSet.changeset(%DataSet{}, %{
      name: name,
      socrata?: soc?,
      state: "new",
      user_id: Plenario.Auth.Guardian.Plug.current_resource(conn).id
    })

    create_action = Routes.data_set_path(conn, :create)
    backout_action = Routes.me_path(conn, :show)

    render conn, "new.html",
      changeset: changeset,
      socrata?: soc?,
      fully_editable?: true,
      create_action: create_action,
      backout_action: backout_action
  end

  def new(conn, params) when params == %{}, do: render conn, "init.html", action: Routes.data_set_path(conn, :new)

  def create(conn, %{"data_set" => form}) do
    DataSetActions.create(form)
    |> do_create(conn)
  end

  defp do_create({:ok, data_set}, conn) do
    try do
      Logger.info("attempting to create fields for #{data_set.name}")
      {:ok, _} = FieldActions.create_for_data_set(data_set)
    rescue
      e in Exception ->
        Logger.error(e.message)
    end

    conn
    |> put_flash(:success, "Created #{data_set.name}")
    |> redirect(to: Routes.data_set_path(conn, :show, data_set))
  end

  defp do_create({:error, changeset}, conn) do
    socrata? = Ecto.Changeset.get_field(changeset, :socrata?)
    create_action = Routes.data_set_path(conn, :create)
    backout_action = Routes.me_path(conn, :show)

    Logger.debug("#{inspect(changeset)}")

    conn
    |> put_status(:bad_request)
    |> put_error_flashes(changeset)
    |> render("new.html",
      changeset: changeset,
      socrata?: socrata?,
      fully_editable?: true,
      create_action: create_action,
      backout_action: backout_action
    )
  end

  def show(conn, %{"id" => id}) do
    user = Guardian.Plug.current_resource(conn)
    data_set = DataSetActions.get!(id, with_user: true, with_fields: true)

    user_is_owner? = user.is_admin? or data_set.user_id == user.id
    ok_to_import? = not Enum.member?(["new", "awaiting_approval", "erred"], data_set.state)
    submittable? = data_set.state == "new"

    render conn, "show.html",
      data_set: data_set,
      user_is_owner?: user_is_owner?,
      ok_to_import?: ok_to_import?,
      submittable?: submittable?,
      virtual_dates: VirtualDateActions.list(for_data_set: data_set, with_fields: true),
      virtual_points: VirtualPointActions.list(for_data_set: data_set, with_fields: true)
  end

  def edit(conn, %{"id" => id}) do
    data_set = DataSetActions.get!(id)
    changeset = DataSet.changeset(data_set, %{})
    fully_editable? = data_set.state == "new"

    update_action = Routes.data_set_path(conn, :update, data_set)
    backout_action = Routes.data_set_path(conn, :show, data_set)

    render conn, "edit.html",
      data_set: data_set,
      changeset: changeset,
      fully_editable?: fully_editable?,
      update_action: update_action,
      backout_action: backout_action
  end

  def update(conn, %{"id" => id, "data_set" => form}) do
    data_set = DataSetActions.get!(id)

    DataSetActions.update(data_set, form)
    |> do_update(conn, data_set)
  end

  defp do_update({:ok, data_set}, conn, _) do
    conn
    |> put_flash(:success, "Updated #{data_set.name}")
    |> redirect(to: Routes.data_set_path(conn, :show, data_set))
  end

  defp do_update({:error, changeset}, conn, data_set) do
    update_action = Routes.data_set_path(conn, :update, data_set)
    backout_action = Routes.data_set_path(conn, :show, data_set)
    fully_editable? = data_set.state == "new"

    conn
    |> put_status(:bad_request)
    |> put_error_flashes(changeset)
    |> render("edit.html",
      data_set: data_set,
      changeset: changeset,
      fully_editable?: fully_editable?,
      update_action: update_action,
      backout_action: backout_action
    )
  end

  def delete(conn, %{"id" => id}) do
    data_set = DataSetActions.get!(id)
    {:ok, _} = DataSetActions.delete(data_set)

    conn
    |> put_flash(:info, "Deleted #{data_set.name}")
    |> redirect(to: Routes.me_path(conn, :show))
  end

  # Additional functionality

  def reload_fields(conn, %{"id" => id}) do
    data_set = DataSetActions.get!(id)

    conn =
      case data_set.state do
        "new" ->
          FieldActions.list(for_data_set: data_set)
          |> Enum.each(&FieldActions.delete/1)

          FieldActions.create_for_data_set(data_set)

          put_flash(conn, :info, "Fields have been reloaded")

        _ ->
          put_flash(conn, :error, "Cannot reload fields when no longer new")
      end

    redirect(conn, to: Routes.data_set_path(conn, :show, data_set))
  end

  def submit_for_approval(conn, %{"id" => id}) do
    data_set = DataSetActions.get!(id)

    conn =
      case data_set.state do
        "new" ->
          {:ok, _} = DataSetActions.update(data_set, state: "awaiting_approval")
          put_flash(conn, :success, "#{data_set.name} has been submitted for approval")

        _ ->
          put_flash(conn, :error, "Cannot submit non-new data sets for approval")
      end

    redirect(conn, to: Routes.data_set_path(conn, :show, data_set))
  end

  def ingest_now(conn, %{"id" => id}) do
    data_set = DataSetActions.get!(id)
    :ok = Etl.import_data_set_on_demand(data_set)

    conn
    |> put_flash(:info, "#{data_set.name} has been added to the ingest queue")
    |> redirect(to: Routes.data_set_path(conn, :show, data_set))
  end
end
