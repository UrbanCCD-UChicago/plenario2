defmodule PlenarioWeb.Testing.DataSetAdminControllerTest do
  use PlenarioWeb.Testing.ConnCase

  import Plenario.Testing.DataCase

  alias Plenario.{
    DataSetActions,
    TableModelRegistry,
    ViewModelRegistry,
    Repo
  }

  setup do
    TableModelRegistry.clear()
    ViewModelRegistry.clear()

    user = create_user(%{}, username: "Some User", email: "user@example.com")
    context = %{user: user}

    ds1 = create_data_set(context, name: "Data Set 1", src_url: "https://example.com/1")
    ds2 = create_data_set(context, name: "Data Set 2", src_url: "https://example.com/2")
    ds3 = create_data_set(context, name: "Data Set 3", src_url: "https://example.com/3")
    ds4 = create_data_set(context, name: "Data Set 4", src_url: "https://example.com/4")
    ds5 = create_data_set(context, name: "Data Set 5", src_url: "https://example.com/5")

    context = Map.put(context, :data_set, ds2)

    f1 = create_field(context, name: "id")
    f2 = create_field(context, name: "name")
    f3 = create_field(context, name: "whatever")

    context = Map.put(context, :field, f3)

    vd = create_virtual_date(context)
    vp = create_virtual_point(context)

    {:ok, _} = DataSetActions.update(ds1, state: "erred")
    {:ok, _} = DataSetActions.update(ds2, state: "awaiting_approval")
    {:ok, _} = DataSetActions.update(ds3, state: "ready")
    {:ok, _} = DataSetActions.update(ds4, state: "awaiting_first_import")

    {:ok, ds1: ds1, ds2: ds2, ds3: ds3, ds4: ds4, ds5: ds5, f1: f1, f2: f2, f3: f3, vd: vd, vp: vp}
  end

  describe "index" do
    @tag :admin
    test "should see a list of erred data sets", %{conn: conn, ds1: ds1} do
      resp =
        conn
        |> get(Routes.data_set_admin_path(conn, :index))
        |> html_response(:ok)

      assert resp =~ "1 Erred"
      assert resp =~ ds1.name
    end

    @tag :admin
    test "should see a list of reviewable data sets", %{conn: conn, ds2: ds2} do
      resp =
        conn
        |> get(Routes.data_set_admin_path(conn, :index))
        |> html_response(:ok)

      assert resp =~ "1 Need Approval"
      assert resp =~ ds2.name
    end
  end

  describe "review" do
    @tag :admin
    test "should see all data set fields", %{conn: conn, ds2: ds2, f1: f1, f2: f2, f3: f3} do
      resp =
        conn
        |> get(Routes.data_set_admin_path(conn, :review, ds2))
        |> html_response(:ok)

      [f1.name, f2.name, f3.name]
      |> Enum.each(& assert resp =~ &1)
    end

    @tag :admin
    test "should see all data set virtual dates", %{conn: conn, ds2: ds2, vd: vd} do
      resp =
        conn
        |> get(Routes.data_set_admin_path(conn, :review, ds2))
        |> html_response(:ok)

      assert resp =~ vd.col_name
    end

    @tag :admin
    test "should see all data set virtual point", %{conn: conn, ds2: ds2, vp: vp} do
      resp =
        conn
        |> get(Routes.data_set_admin_path(conn, :review, ds2))
        |> html_response(:ok)

      assert resp =~ vp.col_name
    end

    @tag :admin
    test "should see a button that approves the data set", %{conn: conn, ds2: ds2} do
      resp =
        conn
        |> get(Routes.data_set_admin_path(conn, :review, ds2))
        |> html_response(:ok)

      accept_href = Routes.data_set_admin_path(conn, :approve, ds2)
      assert resp =~ accept_href
    end

    @tag :admin
    test "should see a button that rejects the data set", %{conn: conn, ds2: ds2} do
      resp =
        conn
        |> get(Routes.data_set_admin_path(conn, :review, ds2))
        |> html_response(:ok)

      reject_href = Routes.data_set_admin_path(conn, :reject, ds2)
      assert resp =~ reject_href
    end
  end

  describe "reject" do
    @tag :admin
    test "data set's state is set back to new", %{conn: conn, ds2: ds2} do
      conn
      |> post(Routes.data_set_admin_path(conn, :reject, ds2))

      data_set = DataSetActions.get!(ds2.id)
      assert data_set.state == "new"
    end
  end

  describe "approve" do
    @tag :admin
    test "data set's state is set to awaiting_first_import", %{conn: conn, ds2: ds2} do
      conn
      |> post(Routes.data_set_admin_path(conn, :approve, ds2))

      data_set = DataSetActions.get!(ds2.id)
      assert data_set.state == "awaiting_first_import"
    end

    @tag :admin
    test "data set table is created", %{conn: conn, ds2: ds2} do
      conn
      |> post(Routes.data_set_admin_path(conn, :approve, ds2))

      model = TableModelRegistry.lookup(ds2)
      Repo.all(model)
    end

    @tag :admin
    test "data set view is created", %{conn: conn, ds2: ds2} do
      conn
      |> post(Routes.data_set_admin_path(conn, :approve, ds2))

      model = ViewModelRegistry.lookup(ds2)
      Repo.all(model)
    end
  end
end
