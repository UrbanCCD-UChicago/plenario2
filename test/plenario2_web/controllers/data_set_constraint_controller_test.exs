defmodule Plenario2Web.DataSetConstraintControllerTest do
  use Plenario2Web.ConnCase, async: true

  alias Plenario2.Actions.{MetaActions, DataSetFieldActions, DataSetConstraintActions}

  alias Plenario2Auth.UserActions

  @username "Test User"
  @password "password"  # omg so secure
  @email "test@example.com"

  @meta_name "Test Data Set"
  @meta_source_url "https://example.com/"

  setup do
    {:ok, user} = UserActions.create @username, @password, @email

    {:ok, meta} = MetaActions.create @meta_name, user.id, @meta_source_url

    DataSetFieldActions.create meta.id, "event id", "text"
    DataSetFieldActions.create meta.id, "long", "float"
    DataSetFieldActions.create meta.id, "lat", "float"
    DataSetFieldActions.create meta.id, "yr", "integer"
    DataSetFieldActions.create meta.id, "mo", "integer"
    DataSetFieldActions.create meta.id, "day", "integer"

    %{meta: meta}
  end

  test ":get_create", %{conn: conn, meta: meta} do
    conn = post(conn, auth_path(conn, :do_login, %{
      "user" => %{
        "email_address" => @email,
        "plaintext_password" => @password
      }
    }))

    response = conn
      |> get(data_set_constraint_path(conn, :get_create, meta.slug))
      |> html_response(:ok)

    assert response =~ "event_id"
    assert response =~ "long"
    assert response =~ "lat"
    assert response =~ "yr"
    assert response =~ "mo"
    assert response =~ "day"
  end

  test ":do_create", %{conn: conn, meta: meta} do
    conn = post(conn, auth_path(conn, :do_login, %{
      "user" => %{
        "email_address" => @email,
        "plaintext_password" => @password
      }
    }))

    conn
    |> post(data_set_constraint_path(conn, :do_create, meta.slug), %{
        "data_set_constraint" => %{
          "meta_id" => meta.id,
          "field_names" => ["event_id"]
        }
      })
    |> html_response(:found)

    assert Enum.count(DataSetConstraintActions.list_for_meta(meta)) == 1
  end
end
