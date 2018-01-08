defmodule Plenario2Web.ConnCase do
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

  import Plenario2Web.Router.Helpers

  alias Plenario2Auth.UserActions

  @endpoint Plenario2Web.Endpoint

  using do
    quote do
      # Import conveniences for testing with connections
      use Phoenix.ConnTest
      import Plenario2Web.Router.Helpers

      # The default endpoint for testing
      @endpoint Plenario2Web.Endpoint
    end
  end

  setup tags do
    # sandbox the db connection
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Plenario2.Repo)

    # create an admin user
    {:ok, admin_user} = UserActions.create("Admin User", "password", "admin@example.com")
    {:ok, admin_user} = UserActions.promote_to_admin(admin_user)

    # create a regular user
    {:ok, reg_user} = UserActions.create("Regular User", "password", "regular@example.com")

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Plenario2.Repo, {:shared, self()})
    end

    # setup connection
    conn_ = Phoenix.ConnTest.build_conn()
    conn =
      cond do
        tags[:auth] ->
          post(
            conn_,
            auth_path(
              conn_,
              :do_login,
              %{"user" => %{
                "email_address" => "regular@example.com",
                "plaintext_password" => "password"
              }}
            )
          )

        tags[:admin] ->
          post(
            conn_,
            auth_path(
              conn_,
              :do_login,
              %{"user" => %{
                "email_address" => "admin@example.com",
                "plaintext_password" => "password"
              }}
            )
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
