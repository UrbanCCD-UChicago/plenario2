defmodule PlenarioEtl do
  alias Plenario.Schemas.Meta

  alias PlenarioEtl.Actions.EtlJobActions

  alias PlenarioEtl.Worker

  def ingest(%Meta{} = meta) do
    {:ok, job} =
      EtlJobActions.create!(meta)
      |> EtlJobActions.start()

    task = Task.async(fn ->
      :poolboy.transaction(
        :worker,
        fn pid -> Worker.process_etl_job(pid, job) end,
        :infinity
      )
    end)

    {job, task}
  end
end
