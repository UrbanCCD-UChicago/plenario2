defmodule PlenarioWeb.DataSetFieldController do
  use PlenarioWeb, :controller

  require Logger

  alias Plenario.Actions.{DataSetFieldActions, MetaActions}
  alias Plenario.Changesets.DataSetFieldChangesets
  alias Plenario.Repo
  alias Plenario.Schemas.DataSetField

  plug(
    :load_and_authorize_resource,
    model: DataSetField,
    id_name: "slug",
    id_field: "slug",
    except: [:detail, :list, :get_create, :do_create]
  )

  def index(conn, %{"slug" => slug}) do
    meta = MetaActions.get(slug)
    fields = DataSetFieldActions.list(for_meta: meta)

    render(conn, "index.html", slug: slug, meta: meta, fields: fields)
  end

  def new(conn, %{"slug" => slug}) do
    changeset = DataSetFieldActions.new()

    render(
      conn,
      "new.html",
      changeset: changeset,
      slug: slug,
      field_type_options: DataSetField.get_type_choices()
    )
  end

  def create(conn, %{"data_set_field" => params, "slug" => slug}) do
    meta = MetaActions.get(slug)
    changeset_params = Map.merge(params, %{"meta_id" => meta.id})
    changeset = DataSetFieldChangesets.create(changeset_params)

    case Repo.insert(changeset) do
      {:ok, field} ->
        conn
        |> put_flash(:info, "#{field.name} created!")
        |> redirect(to: meta_path(conn, :detail, slug))

      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset, slug: slug)
    end
  end

  def edit(conn, %{"slug" => slug, "id" => id}) do
    field = Repo.get!(DataSetField, id)
    changeset = DataSetFieldActions.update(field)

    meta = MetaActions.get(field.meta_id)

    disabled =
      case meta.state == "ready" do
        true -> "disabled"
        false -> false
      end

    if disabled do
      Logger.info("disabled")
    end

    render(
      conn,
      "edit.html",
      field: field,
      changeset: changeset,
      slug: slug,
      field_type_options: DataSetField.get_type_choices(),
      disabled: disabled
    )
  end

  def update(conn, %{"slug" => slug, "id" => id, "data_set_field" => field_params}) do
    field = Repo.get!(DataSetField, id)
    changeset = DataSetFieldChangesets.update(field, field_params)

    case Repo.update(changeset) do
      {:ok, _field} ->
        conn
        |> put_flash(:info, "Data Set Field updated successfully.")
        |> redirect(to: meta_path(conn, :detail, slug))

      {:error, changeset} ->
        render(conn, "edit.html", video: field, changeset: changeset)
    end
  end
end
