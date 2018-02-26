defmodule PlenarioWeb.Admin.ExportJobController do
  use PlenarioWeb, :admin_controller

  alias PlenarioEtl.Actions.ExportJobActions

  def index(conn, _) do
    jobs = ExportJobActions.list()
    # running_now = Enum.filter(jobs, fn j -> j.completed_on == nil end)
    # completed = Enum.filter(jobs, fn j -> j.completed_on != nil end)
    #
    # num_running = length(running_now)
    # num_completed = length(completed)

    render(conn, "index.html",
      # running_now: running_now,
      # completed: completed,
      # num_running: num_running,
      # num_completed: num_completed
      jobs: jobs
    )
  end
end
