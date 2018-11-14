defmodule Plenario.User do
  use Ecto.Schema

  import Ecto.Changeset

  alias Plenario.{
    User,
    DataSet
  }

  schema "users" do
    field :username, :string
    field :email, :string
    field :password_hash, :string
    field :password, :string, virtual: true

    field :bio, :string, default: nil

    field :is_admin?, :boolean, default: false

    has_many :data_sets, DataSet
  end

  defimpl Phoenix.HTML.Safe, for: User, do: def to_iodata(user), do: user.username

  @attrs ~W|username email password bio is_admin?|a

  @reqd ~W|username email|a

  @email_regex ~r/.*@.*\..*/

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, @attrs)
    |> validate_required(@reqd)
    |> validate_format(:email, @email_regex)
    |> unique_constraint(:username)
    |> unique_constraint(:email)
    |> put_password_hash()
  end

  defp put_password_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    hash = Comeonin.Bcrypt.hashpwsalt(password)
    put_change(changeset, :password_hash, hash)

  end

  defp put_password_hash(changeset), do: changeset
end
