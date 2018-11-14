defmodule PlenarioWeb.Testing.ChannelCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use Phoenix.ChannelTest
      @endpoint PlenarioWeb.Endpoint
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Plenario.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Plenario.Repo, {:shared, self()})
    end

    :ok
  end
end
