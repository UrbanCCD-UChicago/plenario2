defmodule Plenario.Seed do
  require Logger

  alias Plenario.Actions.{
    UserActions,
    MetaActions,
    DataSetFieldActions,
    VirtualPointFieldActions
  }

  alias PlenarioAot.AotActions

  @user_name "Plenario Admin"
  @user_email "plenario@uchicago.edu"
  @user_password "password"

  @meta_name "Chicago Beach Lab - DNA Tests"
  @meta_url "https://data.cityofchicago.org/api/views/hmqm-anjq/rows.csv?accessType=DOWNLOAD"
  @meta_src_type "csv"

  @aot_name "Chicago"
  @aot_url "http://www.mcs.anl.gov/research/projects/waggle/downloads/beehive1/plenario.json"

  defp make_user do
    {:ok, user} = UserActions.create(@user_name, @user_email, @user_password)
    {:ok, user} = UserActions.promote_to_admin(user)
    user
  end

  defp make_meta(user) do
    {:ok, meta} = MetaActions.create(@meta_name, user, @meta_url, @meta_src_type)

    {:ok, meta} =
      MetaActions.update(
        meta,
        refresh_rate: "days",
        refresh_interval: 1,
        description: "Lorem Ipsum\nDNA Chicago Beaches\nDolor Sit Amet",
        attribution: "City of Chicago"
      )

    meta
  end

  defp make_fields(meta) do
    {:ok, _} = DataSetFieldActions.create(meta, "DNA Test ID", "text")
    {:ok, _} = DataSetFieldActions.create(meta, "DNA Sample Timestamp", "timestamp")
    {:ok, _} = DataSetFieldActions.create(meta, "Beach", "text")
    {:ok, _} = DataSetFieldActions.create(meta, "DNA Sample 1 Reading", "float")
    {:ok, _} = DataSetFieldActions.create(meta, "DNA Sample 2 Reading", "float")
    {:ok, _} = DataSetFieldActions.create(meta, "DNA Reading Mean", "float")
    {:ok, _} = DataSetFieldActions.create(meta, "Culture Test ID", "text")
    {:ok, _} = DataSetFieldActions.create(meta, "Culture Sample 1 Timestamp", "text")
    {:ok, _} = DataSetFieldActions.create(meta, "Culture Sample 1 Reading", "text")
    {:ok, _} = DataSetFieldActions.create(meta, "Culture Sample 2 Reading", "text")
    {:ok, _} = DataSetFieldActions.create(meta, "Culture Reading Mean", "text")
    {:ok, _} = DataSetFieldActions.create(meta, "Culture Note", "text")
    {:ok, _} = DataSetFieldActions.create(meta, "Culture Sample Interval", "text")
    {:ok, _} = DataSetFieldActions.create(meta, "Culture Sample 2 Timestamp", "text")
    {:ok, lat} = DataSetFieldActions.create(meta, "Latitude", "float")
    {:ok, lon} = DataSetFieldActions.create(meta, "Longitude", "float")
    {:ok, _} = DataSetFieldActions.create(meta, "Location", "text")
    {:ok, _} = VirtualPointFieldActions.create(meta, lat.id, lon.id)

    :ok
  end

  defp make_aot do
    {:ok, aot} = AotActions.create_meta(@aot_name, @aot_url)
    aot
  end

  def seed do
    if Mix.env() != :dev do
      System.halt(1)
    end

    # setup the user
    user = make_user()

    # setup a regular data set
    meta = make_meta(user)
    :ok = make_fields(meta)
    {:ok, meta} = MetaActions.submit_for_approval(meta)
    {:ok, _} = MetaActions.approve(meta)

    # setup aot chicago
    aot = make_aot()

    # dump out info
    msg = """

    =============
      USER INFO
    =============
    email:    #{@user_email}
    password: #{@user_password}

    =============
      META INFO
    =============
    id:   #{meta.id}
    name: #{@meta_name}
    url:  #{@meta_url}

    ============
      AOT INFO
    ============
    id:   #{aot.id}
    name: #{@aot_name}
    url:  #{@aot_url}

    """

    Logger.info(msg)

    :ok
  end
end

Plenario.Seed.seed()
