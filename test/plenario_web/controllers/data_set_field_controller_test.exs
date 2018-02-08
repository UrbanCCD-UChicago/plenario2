# defmodule PlenarioWeb.DataSetFieldControllerTest do
#   use PlenarioWeb.ConnCase, async: true
#
#   alias Plenario.Actions.{DataSetFieldActions, MetaActions}
#   alias Plenario.Schemas.DataSetField
#   alias Plenario.Repo
#
#   @meta_name "test"
#   @meta_source_url "somewhere"
#
#   setup context do
#     {:ok, meta} = MetaActions.create(@meta_name, context.reg_user.id, @meta_source_url)
#
#     %{meta: meta}
#   end
#
#   describe "GET :new" do
#     @tag :anon
#     test "when anonymous", %{conn: conn} do
#       response =
#         conn
#         |> get(data_set_field_path(conn, :new, "some slug"))
#         |> response(:unauthorized)
#
#       assert response =~ "unauthorized"
#     end
#
#     @tag :auth
#     test "when logged in", %{conn: conn, meta: meta} do
#       response =
#         conn
#         |> get(data_set_field_path(conn, :new, meta.slug))
#         |> response(200)
#
#       assert response =~ "New Data Set Field"
#     end
#   end
#
#   describe "POST :create" do
#     @tag :anon
#     test "when anonymous", %{conn: conn} do
#       response =
#         conn
#         |> get(data_set_field_path(conn, :create, "some slug"))
#         |> response(:unauthorized)
#
#       assert response =~ "unauthorized"
#     end
#
#     @tag :auth
#     test "when logged in", %{conn: conn, meta: meta} do
#       conn
#       |> post(data_set_field_path(conn, :create, meta.slug), %{
#         "data_set_field" => %{
#           "name" => "foo",
#           "type" => "text",
#           "opts" => "default null"
#         }
#       })
#       |> response(302)
#
#       fields = DataSetFieldActions.list_for_meta(meta)
#
#       assert Enum.count(fields) == 1
#     end
#   end
#
#   describe "POST :update" do
#     @tag :anon
#     test "when anonymous", %{conn: conn} do
#       response =
#         conn
#         |> get(data_set_field_path(conn, :update, "some slug", -1))
#         |> response(:unauthorized)
#
#       assert response =~ "unauthorized"
#     end
#
#     @tag :auth
#     test "when logged in", %{conn: conn, meta: meta} do
#       conn
#       |> post(data_set_field_path(conn, :create, meta.slug), %{
#         "data_set_field" => %{
#           "name" => "foo",
#           "type" => "text",
#           "opts" => "default null"
#         }
#       })
#       |> response(302)
#
#       fields = DataSetFieldActions.list_for_meta(meta)
#       [field | _] = fields
#
#       conn
#       |> put(data_set_field_path(conn, :update, meta.slug, field.id), %{
#         "data_set_field" => %{
#           "name" => "FOOS",
#           "type" => "integer",
#           "opts" => "default null"
#         }
#       })
#       |> response(302)
#
#       field = Repo.get!(DataSetField, field.id)
#
#       assert field.name == "foos"
#       assert field.type == "integer"
#       assert field.opts == "default null"
#     end
#   end
# end
