defmodule PlenarioWeb.Web.Testing.DataSetControllerTest do
  use PlenarioWeb.Testing.ConnCase, async: true

  alias Plenario.Actions.MetaActions

  setup %{reg_user: user} do
    {:ok, meta} = MetaActions.create("name", user, "https://example.com/", "csv")

    {:ok, [meta: meta]}
  end

  @tag :auth
  test "show", %{conn: conn, meta: meta} do
    conn
    |> get(data_set_path(conn, :show, meta.id))
    |> html_response(:ok)
  end

  @tag :auth
  test "new", %{conn: conn} do
    conn
    |> get(data_set_path(conn, :new))
    |> html_response(:ok)
  end

  describe "create" do
    @tag :auth
    test "with good inputs", %{conn: conn, reg_user: user} do
      params = %{
        "meta" => %{
          "name" => "some new meta",
          "user_id" => user.id,
          "source_url" => "https://example.com/1",
          "source_type" => "csv"
        }
      }

      conn
      |> post(data_set_path(conn, :create, params))
      |> html_response(:found)
    end

    @tag :auth
    test "with bad inputs", %{conn: conn, reg_user: user} do
      params = %{
        "meta" => %{
          "name" => "some new meta",
          "user_id" => user.id,
          "source_url" => "https://example.com/",
          "source_type" => "csv"
        }
      }

      conn
      |> post(data_set_path(conn, :create, params))
      |> html_response(:bad_request)
    end
  end

  @tag :auth
  test "edit", %{conn: conn, meta: meta} do
    conn
    |> get(data_set_path(conn, :edit, meta.id))
    |> html_response(:ok)
  end

  describe "update" do
    @tag :auth
    test "with good inputs", %{conn: conn, meta: meta} do
      new_name = "some new name"
      params = %{
        "meta" => %{
          "name" => new_name,
          "force_fields_reset" => true
        }
      }

      conn
      |> put(data_set_path(conn, :update, meta.id, params))
      |> html_response(:found)

      meta = MetaActions.get(meta.id)
      assert meta.name == new_name
    end

    @tag :auth
    test "with bad inputs", %{conn: conn, meta: meta} do
      params = %{
        "meta" => %{
          "refresh_starts_on" => "whenever",
          "force_fields_reset" => true
        }
      }

      conn
      |> put(data_set_path(conn, :update, meta.id, params))
      |> html_response(:bad_request)
    end
  end

  @tag :auth
  test "submit for approval", %{conn: conn, meta: meta} do
    conn
    |> post(data_set_path(conn, :submit_for_approval, meta.id))
    |> html_response(:found)

    meta = MetaActions.get(meta.id)
    assert meta.state == "needs_approval"
  end

  describe "ingest now" do
    @tag :auth
    test "with an acceptable state", %{conn: conn, meta: meta} do
      {:ok, meta} = MetaActions.submit_for_approval(meta)
      {:ok, meta} = MetaActions.approve(meta)

      conn
      |> post(data_set_path(conn, :ingest_now, meta.id))
      |> html_response(:found)
    end

    @tag :auth
    test "with an unacceptable state", %{conn: conn, meta: meta} do
      conn = post(conn, data_set_path(conn, :ingest_now, meta.id))
      redir_path = redirected_to(conn, :found)

      response =
        get(recycle(conn), redir_path)
        |> html_response(:ok)

      assert response =~ "Cannot ingest at this time"
    end
  end
end
