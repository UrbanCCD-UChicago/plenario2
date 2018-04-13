defmodule Plenario.Changesets.UserChangesetsTest do
  use ExUnit.Case, async: true
  alias Plenario.Changesets.UserChangesets

  test "create/0 registers error for empty passwords" do
    changeset = UserChangesets.create(%{
      name: "username",
      email: "user@email.com",
      password: ""
    })
    
    assert changeset.valid? == false
    assert length(changeset.errors) == 1
    assert List.first(changeset.errors) == {:password, {"can't be blank", [validation: :required]}}
  end

  test "create/0 registers error for password: :empty" do
    changeset = UserChangesets.create(%{
      name: "username",
      email: "user@email.com",
      password: :empty
    })
    
    assert changeset.valid? == false
    assert length(changeset.errors) == 1
    assert List.first(changeset.errors) == {:password, {"is invalid", [type: :string, validation: :cast]}}
  end
end
