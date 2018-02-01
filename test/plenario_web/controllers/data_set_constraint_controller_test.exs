defmodule PlenarioWeb.DataSetConstraintControllerTest do
  use PlenarioWeb.ConnCase, async: true

  alias Plenario.Actions.{MetaActions, DataSetFieldActions, DataSetConstraintActions}

  @meta_name "Test Data Set"
  @meta_source_url "https://example.com/"

  setup context do
    {:ok, meta} = MetaActions.create(@meta_name, context.reg_user.id, @meta_source_url)

    DataSetFieldActions.create(meta.id, "event id", "text")
    DataSetFieldActions.create(meta.id, "long", "float")
    DataSetFieldActions.create(meta.id, "lat", "float")
    DataSetFieldActions.create(meta.id, "yr", "integer")
    DataSetFieldActions.create(meta.id, "mo", "integer")
    DataSetFieldActions.create(meta.id, "day", "integer")

    %{meta: meta}
  end

  @tag :auth
  test ":get_create", %{conn: conn, meta: meta} do
    response =
      conn
      |> get(data_set_constraint_path(conn, :get_create, meta.slug))
      |> html_response(:ok)

    assert response =~ "event_id"
    assert response =~ "long"
    assert response =~ "lat"
    assert response =~ "yr"
    assert response =~ "mo"
    assert response =~ "day"
  end

  @tag :auth
  test ":do_create", %{conn: conn, meta: meta} do
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
