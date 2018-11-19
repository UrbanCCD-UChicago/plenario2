defmodule PlenarioWeb.Testing.DataSetControllerTest do
  use PlenarioWeb.Testing.ConnCase

  import Mock

  import Plenario.Testing.DataCase

  alias Plenario.{
    DataSetActions,
    FieldActions,
    VirtualDateActions,
    VirtualPointActions
  }

  def mock_download(_, _), do: "test/fixtures/id_timestamp.csv"

  def mock_push(_), do: :ok

  describe "new" do
    @tag :auth
    test "without params it presents the init form", %{conn: conn} do
      resp =
        conn
        |> get(Routes.data_set_path(conn, :new))
        |> html_response(:ok)

      assert resp =~ "Sourced directly from Socrata"
      assert resp =~ "Sourced directly from a web resource (e.g. a publicly available CSV)"
      refute resp =~ "soc_domain"
      refute resp =~ "soc_4x4"
      refute resp =~ "src_url"
    end

    @tag :auth
    test "with params %{socrata: true} it presents the socrata form", %{conn: conn} do
      name = "Whatever Data Set"

      resp =
        conn
        |> get(Routes.data_set_path(conn, :new, %{"name" => name, "socrata" => true}))
        |> html_response(:ok)

      assert resp =~ "value=\"#{name}\""
      assert resp =~ "Socrata domain"
      assert resp =~ "Socrata 4x4"
      refute resp =~ "Source URL"
      refute resp =~ "Source type"
    end

    @tag :auth
    test "with params %{socrata: false} it presents the web resource form", %{conn: conn} do
      name = "Whatever Data Set"

      resp =
        conn
        |> get(Routes.data_set_path(conn, :new, %{"name" => name, "socrata" => false}))
        |> html_response(:ok)

      assert resp =~ "value=\"#{name}\""
      refute resp =~ "Socrata domain"
      refute resp =~ "Socrata 4x4"
      assert resp =~ "Source URL"
      assert resp =~ "Source type"
    end
  end

  describe "create" do
    @tag :auth
    test_with_mock "attempts to create fields when data set is created", %{conn: conn, user: user},
      Plenario.Etl.Downloader, [], [download: &mock_download/2] do

      conn
      |> post(Routes.data_set_path(conn, :create, %{"data_set" => %{
        user_id: user.id,
        name: "Test Data Set",
        src_url: "https://example.com/",
        src_type: "csv",
        socrata?: false
      }}))

      data_set =
        DataSetActions.list(for_user: user, with_fields: true)
        |> List.first()

      assert length(data_set.fields) == 2

      cols_types =
        data_set.fields
        |> Enum.map(& {&1.col_name, &1.type})
        |> Enum.into(%{})

      [{"id", "integer"}, {"timestamp", "timestamp"}]
      |> Enum.each(fn {col, type} ->
        assert Map.has_key?(cols_types, col)
        assert cols_types[col] == type
      end)
    end

    @tag :auth
    test_with_mock "redirects to show when created", %{conn: conn, user: user},
      Plenario.Etl.Downloader, [], [download: &mock_download/2] do

      conn =
        conn
        |> post(Routes.data_set_path(conn, :create, %{"data_set" => %{
          user_id: user.id,
          name: "Test Data Set",
          src_url: "https://example.com/",
          src_type: "csv",
          socrata?: false
        }}))

      redir = redirected_to(conn, 302)

      resp =
        conn
        |> recycle()
        |> get(redir)
        |> html_response(:ok)

      assert resp =~ "Test Data Set"
    end

    @tag :auth
    test "displays the changeset when errors are caught", %{conn: conn, user: user} do
      existing = create_data_set(%{user: user})

      resp =
        conn
        |> post(Routes.data_set_path(conn, :create, %{"data_set" => %{
          user_id: user.id,
          name: existing.name,
          src_url: "https://example.com/1",
          src_type: "csv",
          socrata?: false
        }}))
        |> html_response(:bad_request)

      assert resp =~ "has already been taken"
    end
  end

  describe "show" do
    @tag :auth
    test "when user is owner it shows editing actions", %{conn: conn, user: user} do
      data_set = create_data_set(%{user: user})

      resp =
        conn
        |> get(Routes.data_set_path(conn, :show, data_set))
        |> html_response(:ok)

      edit_href = Routes.data_set_path(conn, :edit, data_set)
      assert resp =~ edit_href
    end

    @tag :admin
    test "when user is admin it shows editing actions", %{conn: conn} do
      user = create_user()
      data_set = create_data_set(%{user: user})

      resp =
        conn
        |> get(Routes.data_set_path(conn, :show, data_set))
        |> html_response(:ok)

      edit_href = Routes.data_set_path(conn, :edit, data_set)
      assert resp =~ edit_href
    end

    # @tag :auth
    # test "when user is not the owner or admin it doens't show editing actions", %{conn: conn} do
    #   user = create_user(%{}, username: "other", email: "other@example.com")
    #   data_set = create_data_set(%{user: user})

    #   resp =
    #     conn
    #     |> get(Routes.data_set_path(conn, :show, data_set))
    #     |> html_response(:ok)

    #   edit_href = Routes.data_set_path(conn, :edit, data_set)
    #   refute resp =~ edit_href
    # end

    @tag :auth
    test "when it's ok to submit for approval it shows the action", %{conn: conn, user: user} do
      data_set = create_data_set(%{user: user})

      resp =
        conn
        |> get(Routes.data_set_path(conn, :show, data_set))
        |> html_response(:ok)

      submit_href = Routes.data_set_path(conn, :submit_for_approval, data_set)
      assert resp =~ submit_href
    end

    @tag :auth
    test "when it's ok to import it shows the action", %{conn: conn, user: user} do
      data_set = create_data_set(%{user: user})
      {:ok, _} = DataSetActions.update(data_set, state: "ready")

      resp =
        conn
        |> get(Routes.data_set_path(conn, :show, data_set))
        |> html_response(:ok)

      import_href = Routes.data_set_path(conn, :ingest_now, data_set)
      assert resp =~ import_href
    end
  end

  describe "edit" do
    @tag :auth
    test "shows a the socrata form if the data set is sourced from socrata", %{conn: conn, user: user} do
      data_set = create_data_set(%{user: user}, src_url: nil, soc_domain: "data.cityofchicago.org", soc_4x4: "xpdx-8ivx", socrata?: true)

      resp =
        conn
        |> get(Routes.data_set_path(conn, :edit, data_set))
        |> html_response(:ok)

      refute resp =~ "Source URL"
      assert resp =~ "Socrata domain"
      assert resp =~ "Socrata 4x4"
    end

    @tag :auth
    test "shows a web resource form if the data set is not sourced from socrata", %{conn: conn, user: user} do
      data_set = create_data_set(%{user: user})

      resp =
        conn
        |> get(Routes.data_set_path(conn, :edit, data_set))
        |> html_response(:ok)

      assert resp =~ "Source URL"
      refute resp =~ "Socrata domain"
      refute resp =~ "Socrata 4x4"
    end
  end

  describe "update" do
    @tag :auth
    test "redirects to show when successful", %{conn: conn, user: user} do
      data_set = create_data_set(%{user: user})

      new_description = "blah blah blah blah blah"
      conn =
        conn
        |> put(Routes.data_set_path(conn, :update, data_set, %{"data_set" => %{"description" => new_description}}))

      redir = redirected_to(conn, 302)

      resp =
        conn
        |> recycle()
        |> get(redir)
        |> html_response(:ok)

      assert resp =~ new_description
    end

    @tag :auth
    test "stays on form and shows changset when there are errors", %{conn: conn, user: user} do
      data_set = create_data_set(%{user: user})

      resp =
        conn
        |> put(Routes.data_set_path(conn, :update, data_set, %{"data_set" => %{"src_url" => "unreachable"}}))
        |> html_response(:bad_request)

      assert resp =~ "has invalid format"
    end
  end

  describe "delete" do
    @tag :auth
    test "deletes all related fields and virtual properties", %{conn: conn, user: user} do
      data_set = create_data_set(%{user: user})
      field = create_field(%{data_set: data_set})
      create_virtual_date(%{data_set: data_set, field: field})
      create_virtual_point(%{data_set: data_set, field: field})

      conn
      |> delete(Routes.data_set_path(conn, :delete, data_set))
      |> html_response(302)

      assert {:error, nil} == DataSetActions.get(data_set.id)
      assert length(FieldActions.list(for_data_set: data_set.id)) == 0
      assert length(VirtualDateActions.list(for_data_set: data_set.id)) == 0
      assert length(VirtualPointActions.list(for_data_set: data_set.id)) == 0
    end
  end

  describe "reload_fields" do
    @tag :auth
    test_with_mock "will delete existing fields", %{conn: conn, user: user},
      Plenario.Etl.Downloader, [], [download: &mock_download/2] do

      data_set = create_data_set(%{user: user})
      field = create_field(%{data_set: data_set})

      conn
      |> post(Routes.data_set_path(conn, :reload_fields, data_set))
      |> html_response(302)

      assert {:error, nil} == FieldActions.get(field.id)
    end

    @tag :auth
    test_with_mock "will attempt to create fields from source material", %{conn: conn, user: user},
      Plenario.Etl.Downloader, [], [download: &mock_download/2] do

      data_set = create_data_set(%{user: user})
      create_field(%{data_set: data_set})

      conn
      |> post(Routes.data_set_path(conn, :reload_fields, data_set))
      |> html_response(302)

      data_set =
        DataSetActions.list(for_user: user, with_fields: true)
        |> List.first()

      assert length(data_set.fields) == 2

      cols_types =
        data_set.fields
        |> Enum.map(& {&1.col_name, &1.type})
        |> Enum.into(%{})

      [{"id", "integer"}, {"timestamp", "timestamp"}]
      |> Enum.each(fn {col, type} ->
        assert Map.has_key?(cols_types, col)
        assert cols_types[col] == type
      end)
    end
  end

  describe "submit_for_approval" do
    @tag :auth
    test "will redirect to show", %{conn: conn, user: user} do
      data_set = create_data_set(%{user: user})

      conn =
        conn
        |> post(Routes.data_set_path(conn, :submit_for_approval, data_set))

      redir = redirected_to(conn, 302)

      resp =
        conn
        |> recycle()
        |> get(redir)
        |> html_response(:ok)

      assert resp =~ "#{data_set.name} has been submitted for approval"
    end

    @tag :auth
    test "will update the state to awaiting approval if the state is new", %{conn: conn, user: user} do
      data_set = create_data_set(%{user: user})

      conn =
        conn
        |> post(Routes.data_set_path(conn, :submit_for_approval, data_set))

      redir = redirected_to(conn, 302)

      resp =
        conn
        |> recycle()
        |> get(redir)
        |> html_response(:ok)

      assert resp =~ "awaiting_approval"
    end

    @tag :auth
    test "will flash an error message if the state isn't new", %{conn: conn, user: user} do
      data_set = create_data_set(%{user: user})
      {:ok, _} = DataSetActions.update(data_set, state: "erred")

      conn =
        conn
        |> post(Routes.data_set_path(conn, :submit_for_approval, data_set))

      redir = redirected_to(conn, 302)

      resp =
        conn
        |> recycle()
        |> get(redir)
        |> html_response(:ok)

      assert resp =~ "Cannot submit non-new data sets for approval"
    end
  end

  describe "ingest_now" do
    @tag :auth
    test_with_mock "will redirect to show", %{conn: conn, user: user},
      Plenario.Etl.Queue, [], [push: &mock_push/1] do

      data_set = create_data_set(%{user: user})
      {:ok, _} = DataSetActions.update(data_set, state: "ready")

      conn =
        conn
        |> post(Routes.data_set_path(conn, :ingest_now, data_set))

      redir = redirected_to(conn, 302)

      resp =
        conn
        |> recycle()
        |> get(redir)
        |> html_response(:ok)

      assert resp =~ "#{data_set.name} has been added to the ingest queue"
    end

    @tag :auth
    test_with_mock "will add the data set to the etl queue", %{conn: conn, user: user},
      Plenario.Etl.Queue, [], [push: &mock_push/1] do

      data_set = create_data_set(%{user: user})
      {:ok, _} = DataSetActions.update(data_set, state: "ready")

      conn =
        conn
        |> post(Routes.data_set_path(conn, :ingest_now, data_set))

      redir = redirected_to(conn, 302)

      conn
      |> recycle()
      |> get(redir)
      |> html_response(:ok)

      data_set = DataSetActions.get!(data_set.id)
      assert_called Plenario.Etl.Queue.push(data_set)
    end
  end
end
