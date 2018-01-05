defmodule Plenario2.Actions.AdminUserNoteActions do
  @moduledoc """
  This module provides a common API for the business logic
  underlying the various public interfaces for AdminUserNotes.
  """

  import Plenario2.Guards, only: [is_id: 1]

  alias Plenario2.Repo
  alias Plenario2.Schemas.{AdminUserNote, Meta}
  alias Plenario2.Changesets.AdminUserNoteChangesets
  alias Plenario2.Queries.AdminUserNoteQueries, as: Q

  alias Plenario2Auth.User

  @typedoc """
  Parameter is an ID attribute
  """
  @type id :: String.t | integer

  @typedoc """
  Parameter is an _admin_ User
  """
  @type t_admin :: %User{is_admin: true} | id

  @typedoc """
  Returns a tuple of :ok, AdminUserNote or :error, Ecto.Changeset
  """
  @type ok_note :: {:ok, AdminUserNote} | {:error, Ecto.Changeset.T}

  @doc """
  Gets a single AdminUserNote by ID, optionally preloading relations.
  See the notes for AdminUserNoteQueries.handle_opts
  """
  @spec get_from_id(id :: integer, opts :: %{}) :: %AdminUserNote{} | nil
  def get_from_id(id, opts \\ []) do
    Q.from_id(id)
    |> Q.handle_opts(opts)
    |> Repo.one()
  end

  @doc """
  Gets a list of AdminUserNotes, optionally filtering and preloading relations.
  See the notes for AdminUserNoteQueries.handle_opts
  """
  @spec list(opts :: %{}) :: [%AdminUserNote{}]
  def list(opts \\ []) do
    Q.list()
    |> Q.handle_opts(opts)
    |> Repo.all()
  end

  @doc """
  Creates a new AdminUserNote related to a Meta.
  """
  @spec create_for_meta(note :: String.t, admin :: t_admin, user :: User | id, meta :: Meta | id, should_email :: boolean) :: ok_note
  def create_for_meta(note, admin, user, meta, should_email \\ false) do
    admin_id =
      case is_id(admin) do
        true -> admin
        false -> admin.id
      end

    user_id =
      case is_id(user) do
        true -> user
        false -> user.id
      end

    meta_id =
      case is_id(meta) do
        true -> meta
        false -> meta.id
      end

    params = %{
      note: note,
      should_email: should_email,
      admin_id: admin_id,
      user_id: user_id,
      meta_id: meta_id
    }
    AdminUserNoteChangesets.create_for_meta(%AdminUserNote{}, params)
    |> Repo.insert()
  end

  # def create_for_etl_job(note, admin, user, etl_job, should_email \\ false) do
  #   params = %{
  #     note: note,
  #     should_email: should_email,
  #     admin_id: admin.id,
  #     user_id: user.id,
  #     etl_job_id: etl_job.id
  #   }
  #   AdminUserNoteChangesets.create_for_etl_job(%AdminUserNote{}, params)
  #   |> Repo.insert()
  # end

  # def create_for_export_job(note, admin, user, export_job, should_email \\ false) do
  #   params = %{
  #     note: note,
  #     should_email: should_email,
  #     admin_id: admin.id,
  #     user_id: user.id,
  #     export_job_id: export_job.id
  #   }
  #   AdminUserNoteChangesets.create_for_export_job(%AdminUserNote{}, params)
  #   |> Repo.insert()
  # end

  @doc """
  Updates a given note in the database as having been acknowledged by the user.
  """
  @spec mark_acknowledged(note :: AdminUserNote) :: {:ok, %AdminUserNote{} | :error, Ecto.Changeset.t}
  def mark_acknowledged(note) do
    AdminUserNoteChangesets.update_acknowledged(note, %{acknowledged: true})
    |> Repo.update()
  end

  # TODO: def send_email(note)
end
