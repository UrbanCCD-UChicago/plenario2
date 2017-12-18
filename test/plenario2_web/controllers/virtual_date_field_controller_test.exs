defmodule Plenario2Web.VirtualDateFieldControllerTest do
  use Plenario2Web.ConnCase, async: true

  alias Plenario2.Actions.{MetaActions, DataSetFieldActions, VirtualDateFieldActions}

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
      |> get(virtual_date_field_path(conn, :get_create, meta.slug))
      |> html_response(:ok)

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
    |> post(virtual_date_field_path(conn, :do_create, meta.slug), %{
        "virtual_date_field" => %{
          "meta_id" => meta.id,
          "year_field" => "yr",
          "month_field" => "mo",
          "day_field" => "day",
          "hour_field" => "",
          "minute_field" => "",
          "second_field" => "",
        }
      })
    |> html_response(:found)

    assert Enum.count(VirtualDateFieldActions.list_for_meta(meta)) == 1
  end
end
