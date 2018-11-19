defmodule PlenarioWeb.Testing.ConnCase do
  use ExUnit.CaseTemplate

  use Phoenix.ConnTest

  alias PlenarioWeb.Router.Helpers, as: Routes

  alias Plenario.UserActions

  @endpoint PlenarioWeb.Endpoint

  using do
    quote do
      use Phoenix.ConnTest
      alias PlenarioWeb.Router.Helpers, as: Routes
      @endpoint PlenarioWeb.Endpoint
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Plenario.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Plenario.Repo, {:shared, self()})
    end

    context =
      cond do
        tags[:admin] ->
          email = "admin@example.com"
          password = "password"

          {:ok, user} = UserActions.create(username: "Admin User", email: email, password: password, is_admin?: true)

          conn = Phoenix.ConnTest.build_conn()
          conn =
            conn
            |> post(Routes.session_path(conn, :login, %{"user" => %{"email" => email, "password" => password}}))

          %{user: user, conn: conn}

        tags[:auth] ->
          email = "test@example.com"
          password = "password"

          {:ok, user} = UserActions.create(username: "Test User", email: email, password: password)

          conn = Phoenix.ConnTest.build_conn()
          conn =
            conn
            |> post(Routes.session_path(conn, :login, %{"user" => %{"email" => email, "password" => password}}))

          %{user: user, conn: conn}

        true ->
          %{conn: Phoenix.ConnTest.build_conn()}
      end

    {:ok, context}
  end
end
