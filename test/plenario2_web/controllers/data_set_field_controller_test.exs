defmodule Plenario2Web.DataSetFieldControllerTest do
  use Plenario2Web.ConnCase, async: true
  alias Plenario2.Actions.{DataSetFieldActions, MetaActions}
  alias Plenario2.Schemas.DataSetField
  alias Plenario2.Repo
  alias Plenario2Auth.UserActions

  @user_name "user"
  @user_password "password"
  @user_email "email@example.com"

  @meta_name "test"
  @meta_source_url "somewhere"

  setup do
    {:ok, user} = UserActions.create(@user_name, @user_password, @user_email)
    {:ok, meta} = MetaActions.create(@meta_name, user.id, @meta_source_url)

    %{
      meta: meta,
      user: user
    }
  end

  describe "GET :new" do
    test "when anonymous", %{conn: conn} do
      response = conn
        |> get(data_set_field_path(conn, :new, "some slug"))
        |> response(:unauthorized)

      assert response =~ "unauthorized"
    end

    test "when logged in", %{conn: conn, meta: meta} do
      conn = post(conn, auth_path(conn, :do_login, %{
        "user" => %{
          "email_address" => @user_email,
          "plaintext_password" => @user_password
        }
      }))

      response = conn
        |> get(data_set_field_path(conn, :new, meta.slug))
        |> response(200)

      assert response =~ "New Data Set Field"
    end
  end

  describe "POST :create" do
    test "when anonymous", %{conn: conn} do
      response = conn
        |> get(data_set_field_path(conn, :create, "some slug"))
        |> response(:unauthorized)

      assert response =~ "unauthorized"
    end

    test "when logged in", %{conn: conn, meta: meta} do
      conn = post(conn, auth_path(conn, :do_login, %{
        "user" => %{
          "email_address" => @user_email,
          "plaintext_password" => @user_password
        }
      }))

      conn
        |> post(data_set_field_path(conn, :create, meta.slug), %{
          "data_set_field" => %{
            "name" => "foo",
            "type" => "text",
            "opts" => "default null"
          }
        })
        |> response(302)

      fields = DataSetFieldActions.list_for_meta(meta)

      assert Enum.count(fields) == 1
    end
  end

  describe "POST :update" do
    test "when anonymous", %{conn: conn} do
      response = conn
        |> get(data_set_field_path(conn, :update, "some slug", -1))
        |> response(:unauthorized)

      assert response =~ "unauthorized"
    end

    test "when logged in", %{conn: conn, meta: meta} do
      conn = post(conn, auth_path(conn, :do_login, %{
        "user" => %{
          "email_address" => @user_email,
          "plaintext_password" => @user_password
        }
      }))

      conn
        |> post(data_set_field_path(conn, :create, meta.slug), %{
          "data_set_field" => %{
            "name" => "foo",
            "type" => "text",
            "opts" => "default null"
          }
        })
        |> response(302)

      fields = DataSetFieldActions.list_for_meta(meta)
      [field | _] = fields

      conn
        |> put(data_set_field_path(conn, :update, meta.slug, field.id), %{
          "data_set_field" => %{
            "name" => "FOOS",
            "type" => "integer",
            "opts" => "default null"
          }
        })
        |> response(302)

      field = Repo.get!(DataSetField, field.id)

      assert field.name == "foos"
      assert field.type == "integer"
      assert field.opts == "default null"
    end
  end
end
