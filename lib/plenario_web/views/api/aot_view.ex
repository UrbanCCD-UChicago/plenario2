defmodule PlenarioWeb.Api.AotView do
  @moduledoc """
  """

  use PlenarioWeb, :api_view

  defdelegate render(view, opts), to: PlenarioWeb.Api.DetailView
end
