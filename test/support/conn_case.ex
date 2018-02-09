defmodule PlenarioWeb.Testing.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common datastructures and query the data layer.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  use Phoenix.ConnTest

  import PlenarioWeb.Router.Helpers

  alias Plenario.Actions.UserActions

  @endpoint PlenarioWeb.Endpoint

  using do
    quote do
      # Import conveniences for testing with connections
      use Phoenix.ConnTest
      import PlenarioWeb.Router.Helpers

      # The default endpoint for testing
      @endpoint PlenarioWeb.Endpoint
    end
  end

  setup tags do
    # sandbox the db connection
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Plenario.Repo)

    # create an admin user
    {:ok, admin_user} = UserActions.create("Admin User", "admin@example.com", "password")
    {:ok, admin_user} = UserActions.promote_to_admin(admin_user)

    # create a regular user
    {:ok, reg_user} = UserActions.create("Regular User", "regular@example.com", "password")

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Plenario.Repo, {:shared, self()})
    end

    # setup connection
    conn_ = Phoenix.ConnTest.build_conn()

    conn =
      cond do
        tags[:auth] ->
          post(
            conn_,
            auth_path(conn_, :login, %{
              "user" => %{
                "email" => "regular@example.com",
                "password" => "password"
              }
            })
          )

        tags[:admin] ->
          post(
            conn_,
            auth_path(conn_, :login, %{
              "user" => %{
                "email" => "admin@example.com",
                "password" => "password"
              }
            })
          )

        tags[:anon] ->
          conn_

        true ->
          conn_
      end

    # return stuff
    {
      :ok,
      [
        conn: conn,
        admin_user: admin_user,
        reg_user: reg_user
      ]
    }
  end
end
