defmodule PlenarioMailer.Actions.AdminUserNoteActions do
  @moduledoc """
  This module provides a common API for the business logic
  underlying the various public interfaces for AdminUserNotes.
  """

  alias Plenario.Repo
  alias Plenario.Schemas.{Meta, User}

  alias PlenarioMailer
  alias PlenarioMailer.Emails
  alias PlenarioMailer.Schemas.AdminUserNote
  alias PlenarioMailer.Changesets.AdminUserNoteChangesets
  alias PlenarioMailer.Queries.AdminUserNoteQueries, as: Q

  require Logger

  @typedoc """
  Returns a tuple of :ok, AdminUserNote or :error, Ecto.Changeset
  """
  @type ok_note :: {:ok, AdminUserNote} | {:error, Ecto.Changeset.T}

  @doc """
  Gets a single AdminUserNote by ID, optionally preloading relations.
  See the notes for AdminUserNoteQueries.handle_opts
  """
  @spec get(id :: id, opts :: Keyword.t()) :: AdminUserNote | nil
  def get(id, opts \\ []) do
    Q.from_id(id)
    |> Q.handle_opts(opts)
    |> Repo.one()
  end

  @doc """
  Gets a list of AdminUserNotes, optionally filtering and preloading relations.
  See the notes for AdminUserNoteQueries.handle_opts
  """
  @spec list(opts :: Keyword.t()) :: list(AdminUserNote)
  def list(opts \\ []) do
    Q.list()
    |> Q.handle_opts(opts)
    |> Repo.all()
  end

  @doc """
  Creates a new AdminUserNote related to a Meta.
  """
  @spec create_for_meta(
          message :: String.t(),
          admin :: %User{is_admin: true},
          user :: User,
          meta :: Meta,
          should_email :: boolean
        ) :: ok_note
  def create_for_meta(message, admin, user, meta, should_email \\ false) do
    params = %{
      message: message,
      should_email: should_email,
      admin_id: admin.id,
      user_id: user.id,
      meta_id: meta.id
    }

    Logger.info("Creating AdminUserNote: #{inspect(params)}")

    {status, note} =
      AdminUserNoteChangesets.create_for_meta(params)
      |> Repo.insert()

    if status == :ok and should_email do
      Emails.compose_admin_user_note(note)
      |> Mailer.deliver_now()
    end

    {status, note}
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
  @spec mark_acknowledged(note :: AdminUserNote) :: ok_note
  def mark_acknowledged(note) do
    AdminUserNoteChangesets.update_acknowledged(note, %{acknowledged: true})
    |> Repo.update()
  end
end
