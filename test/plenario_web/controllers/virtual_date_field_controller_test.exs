# defmodule PlenarioWeb.VirtualDateFieldControllerTest do
#   use PlenarioWeb.ConnCase, async: true
#
#   alias Plenario.Actions.{MetaActions, DataSetFieldActions, VirtualDateFieldActions}
#
#   @meta_name "Test Data Set"
#   @meta_source_url "https://example.com/"
#
#   setup context do
#     {:ok, meta} = MetaActions.create(@meta_name, context.reg_user.id, @meta_source_url)
#
#     DataSetFieldActions.create(meta.id, "event id", "text")
#     DataSetFieldActions.create(meta.id, "long", "float")
#     DataSetFieldActions.create(meta.id, "lat", "float")
#     DataSetFieldActions.create(meta.id, "yr", "integer")
#     DataSetFieldActions.create(meta.id, "mo", "integer")
#     DataSetFieldActions.create(meta.id, "day", "integer")
#
#     %{meta: meta}
#   end
#
#   @tag :auth
#   test ":get_create", %{conn: conn, meta: meta} do
#     response =
#       conn
#       |> get(virtual_date_field_path(conn, :get_create, meta.slug))
#       |> html_response(:ok)
#
#     assert response =~ "yr"
#     assert response =~ "mo"
#     assert response =~ "day"
#   end
#
#   @tag :auth
#   test ":do_create", %{conn: conn, meta: meta} do
#     conn
#     |> post(virtual_date_field_path(conn, :do_create, meta.slug), %{
#       "virtual_date_field" => %{
#         "meta_id" => meta.id,
#         "year_field" => "yr",
#         "month_field" => "mo",
#         "day_field" => "day",
#         "hour_field" => "",
#         "minute_field" => "",
#         "second_field" => ""
#       }
#     })
#     |> html_response(:found)
#
#     assert Enum.count(VirtualDateFieldActions.list_for_meta(meta)) == 1
#   end
# end
