defmodule PlenarioWeb.Api.DetailView do
  @moduledoc """
  """

  use PlenarioWeb, :api_view

  def render("get.json", opts) do
    %{
      meta: %{
        links: opts[:links],
        counts: opts[:counts],
        params: opts[:params]
      },
      data: opts[:data] |> clean()
    }
  end

  def render("head.json", opts) do
    %{
      meta: %{
        links: opts[:links],
        counts: opts[:counts],
        params: opts[:params]
      },
      data: opts[:data] |> clean() |> Enum.take(1)
    }
  end

  def render("describe.json", opts) do
    %{
      meta: %{
        links: opts[:links],
        counts: opts[:counts],
        params: opts[:params]
      },
      data: opts[:data] |> clean()
    }
  end
end
