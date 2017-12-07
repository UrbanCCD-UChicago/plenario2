defmodule Plenario2.Actions.AdminUserNoteActions do
  alias Plenario2.Repo
  alias Plenario2.Schemas.AdminUserNote
  alias Plenario2.Changesets.AdminUserNoteChangesets
  alias Plenario2.Queries.AdminUserNoteQueries, as: Q

  def get_from_id(id, opts \\ []) do
    Q.from_id(id)
    |> Q.handle_opts(opts)
    |> Repo.one()
  end

  def list(opts \\ []) do
    Q.list()
    |> Q.handle_opts(opts)
    |> Repo.all()
  end

  def create_for_meta(note, admin, user, meta, should_email \\ false) do
    params = %{
      note: note,
      should_email: should_email,
      admin_id: admin.id,
      user_id: user.id,
      meta_id: meta.id
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

  def mark_acknowledged(note) do
    AdminUserNoteChangesets.update_acknowledged(note, %{acknowledged: true})
    |> Repo.update()
  end

  # TODO: def send_email(note)
end
