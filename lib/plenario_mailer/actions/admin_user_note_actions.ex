defmodule PlenarioMailer.Actions.AdminUserNoteActions do
  @moduledoc """
  This module provides a common API for the business logic
  underlying the various public interfaces for AdminUserNotes.
  """

  alias Plenario.Repo

  alias Plenario.Schemas.{Meta, User}

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
  Gets a single AdminUserNote given its ID.
  """
  @spec get(identifier :: integer) :: AdminUserNote | nil
  def get(identifier), do: Repo.get_by(AdminUserNote, id: identifier)

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
  @spec create_for_meta(meta :: Meta | integer, admin :: User | integer, user :: User | integer, message :: String.t(), should_email :: boolean) :: ok_note
  def create_for_meta(%Meta{} = meta, admin, user, message, should_email),
    do: create_for_meta(meta.id, admin, user, message, should_email)
  def create_for_meta(meta, %User{} = admin, user, message, should_email),
    do: create_for_meta(meta, admin.id, user, message, should_email)
  def create_for_meta(meta, admin, %User{} = user, message, should_email),
    do: create_for_meta(meta, admin, user.id, message, should_email)
  def create_for_meta(meta, admin, user, message, should_email) do
    params = %{
      meta_id: meta,
      admin_id: admin,
      user_id: user,
      message: message,
      should_email: should_email
    }

    {status, note} =
      AdminUserNoteChangesets.create_for_meta(params)
      |> Repo.insert()

    if status == :ok and should_email do
      Emails.compose_admin_user_note(note)
      |> PlenarioMailer.deliver_now()
    end

    {status, note}
  end

  @doc """
  Updates a given note in the database as having been acknowledged by the user.
  """
  @spec mark_acknowledged(note :: AdminUserNote) :: ok_note
  def mark_acknowledged(note) do
    AdminUserNoteChangesets.update_acknowledged(note, %{acknowledged: true})
    |> Repo.update()
  end
end
