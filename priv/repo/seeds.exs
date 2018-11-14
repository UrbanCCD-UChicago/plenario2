alias Plenario.{UserActions, DataSetActions, FieldActions, Repo}
{:ok, user} = UserActions.create(username: "Plenario Admin", email: "plenario@uchicago.edu", password: "password", is_admin?: true)
{:ok, ds} = DataSetActions.create(name: "Chicago 311 Tree Trims", soc_domain: "data.cityofchicago.org", soc_4x4: "yvxb-fxjz", src_type: "json", socrata?: true, user: user)
{:ok, _} = FieldActions.create_for_data_set(ds)
:ok = Repo.up!(ds)
{:ok, _} = DataSetActions.update(ds, state: "ready")
