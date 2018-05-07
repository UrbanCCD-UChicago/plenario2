defmodule PlenarioAot.AotScheduler do
  use Quantum.Scheduler, otp_app: :plenario

  alias PlenarioAot.AotWorker

  def import_aot_data do
    task =
      Task.async(fn ->
        :poolboy.transaction(
          :aot_worker,
          fn pid -> AotWorker.process_observation_batch(pid) end,
          :infinity
        )
      end)

    task
  end
end
