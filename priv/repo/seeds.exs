defmodule Plenario.DevSeed do
  import Ecto.Query

  alias Plenario.Repo

  alias Plenario.Actions.{
    UserActions,
    MetaActions,
    DataSetFieldActions,
    VirtualPointFieldActions
  }

  alias Plenario.Schemas.Meta

  @beach_lab_name "Chicago Beach Lab - DNA Tests"

  @beach_lab_url "https://data.cityofchicago.org/api/views/hmqm-anjq/rows.csv?accessType=DOWNLOAD"

  def seed_regular do
    if Mix.env() != :dev do
      error = "This should only be run in the dev enviornment! -- you are in #{Mix.env()}"
      IO.puts(error)
      raise "This should only be run in the dev enviornment! -- you are in #{Mix.env()}"
    end

    found = Repo.one(from m in Meta, where: m.name == ^@beach_lab_name)
    if !is_nil(found) do
      error = "Beach lab data already seeded!"
      IO.puts(error)
      raise error
    end

    user =
      case UserActions.get("plenario@uchicago.edu") do
        nil ->
          {:ok, user} = UserActions.create("Plenario Admin", "plenario@uchicago.edu", "password")
          user

        uzer ->
          uzer
      end

    {:ok, user} = UserActions.promote_to_admin(user)
    IO.puts("default user created. email: `plenario@uchicago.edu` ; password: `password`")

    {:ok, meta} = MetaActions.create(@beach_lab_name, user, @beach_lab_url, "csv")
    {:ok, meta} = MetaActions.update meta,
      refresh_starts_on: NaiveDateTime.utc_now(),
      description: "blah blah blah this is a test data set even though it's a real data set\n\ni'm a new paragraph",
      attribution: "City of Chicago",
      refresh_rate: "days",
      refresh_interval: 1

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
    {:ok, loc} = DataSetFieldActions.create(meta, "Location", "text")
    {:ok, _} = VirtualPointFieldActions.create(meta, lat.id, lon.id)
    {:ok, _} = VirtualPointFieldActions.create(meta, loc.id)

    {:ok, meta} = MetaActions.submit_for_approval(meta)
    {:ok, meta} = MetaActions.approve(meta)
    IO.puts("data set `#{meta.name}` is up")
  end

  alias PlenarioAot.{AotActions, AotMeta}

  @aot_name "Chicago"

  @aot_url "http://www.mcs.anl.gov/research/projects/waggle/downloads/beehive1/plenario.json"

  def seed_aot do
    if Mix.env() != :dev do
      error = "This should only be run in the dev enviornment -- you are in #{Mix.env()}!"
      IO.puts(error)
      raise error
    end

    found = Repo.one(from m in AotMeta, where: m.network_name == ^@aot_name)
    if !is_nil(found) do
      error = "AoT Chicago data already seeded!"
      IO.puts(error)
      raise error
    end

    {:ok, _} = AotActions.create_meta(@aot_name, @aot_url)
    IO.puts("AoT #{@aot_name} created -- let it run for 10 minutes to pull in live data")
  end
end


try do
  Plenario.DevSeed.seed_regular()
rescue
  _ ->
    :ok
end

try do
  Plenario.DevSeed.seed_aot()
rescue
  _ ->
    :ok
end
