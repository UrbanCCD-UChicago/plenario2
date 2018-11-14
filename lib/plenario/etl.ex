defmodule Plenario.Etl do
  use Quantum.Scheduler, otp_app: :plenario

  import Ecto.Query

  alias Plenario.{
    DataSet,
    Repo
  }

  alias Plenario.Etl.Queue

  def find_data_sets do
    query =
      from d in DataSet,
      where: d.state in ["ready", "awaiting_first_import"],
      where: fragment("? <= now()", d.refresh_starts_on),
      where: is_nil(d.refresh_ends_on) or fragment("? >= now()", d.refresh_ends_on),
      where: is_nil(d.next_import) or fragment("? <= now()", d.next_import)

    Repo.all(query)
  end

  def import_data_sets, do: find_data_sets() |> Queue.push()

  def import_data_set_on_demand(%DataSet{} = ds), do: Queue.push(ds)
end
