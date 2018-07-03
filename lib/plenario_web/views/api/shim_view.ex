defmodule PlenarioWeb.Api.ShimView do
  require Logger

  import PlenarioWeb.Api.DetailView, only: [clean: 1]

  # todo(heyzoos) refactor what gets passed in as params
  #   - Currently I just toss the whole kitchen sink at you and say:
  #     "From this pile of shit construct a meaningful response"
  #   - It would be nice if we formalized this as a struct with just
  #     the necessary information
  def render("get.json", params) do 
    %{
      meta: %{
        message: "",
        total: params[:total_records],
        query: params[:params],
        status: "ok"
      },
      objects: clean(params[:data])
    }
  end
end