defmodule PlenarioWeb.Web.DataSetController do
  use PlenarioWeb, :web_controller

  alias Plenario.Actions.{DataSetFieldActions, MetaActions}

  alias Plenario.Schemas.{DataSetField, Meta, UniqueConstraint}

  # plug(
  #   :load_and_authorize_resource,
  #   model: Meta,
  #   id_name: "id",
  #   id_field: "id",
  #   except: [:show, :list]
  # )

  def show(conn, %{"id" => id}) do
    meta = MetaActions.get(id,
      with_user: true, with_fields: true, with_constraints: true,
      with_virtual_dates: true, with_virtual_points: true)
    render(conn, "show.html", meta: meta)
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
        field_types = MetaActions.guess_field_types(meta)
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
    update_params = Map.get(params, "meta")
    original_source = meta.source_url
    updated_source = Map.get(update_params, "source_url")
    reset_fields = original_source != updated_source
    force_fields_reset = force_fields_reset == "true"

    update_params = Enum.into(update_params, [])
    case MetaActions.update(meta, update_params) do
      {:ok, meta} ->
        if reset_fields or force_fields_reset do
          IO.puts("resetting fields: #{reset_fields} or #{force_fields_reset}")
          field_types = MetaActions.guess_field_types(meta)
          fields = DataSetFieldActions.list(for_meta: meta)
          for f <- fields, do: DataSetFieldActions.delete(f)
          for {name, type} <- field_types, do: DataSetFieldActions.create(meta, "#{name}", type)
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
        |> render(
          "edit.html", meta: meta, changeset: changeset, action: action,
          source_type_choices: source_type_choices,
          refresh_rate_choices: refresh_rate_choices
        )
    end
  end

  def submit_for_approval(conn, %{"id" => id}) do
  end
end
