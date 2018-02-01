defmodule Plenario.Schemas.User do
  @moduledoc """
  Defines the schema for Users
  """

  use Ecto.Schema

  schema "users" do
    field :name, :string
    field :email, :string

    field :password, :string, virtual: true
    field :password_hash, :string

    field :bio, :string, default: nil

    field :is_active, :boolean, default: true
    field :is_admin, :boolean, default: false

    timestamps(type: :utc_datetime)

    has_many :metas, Plenario.Schemas.Meta
  end
end
