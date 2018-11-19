defmodule Plenario.Testing.DataCase do
  use ExUnit.CaseTemplate

  alias Plenario.{
    UserActions,
    DataSetActions,
    FieldActions,
    VirtualDateActions,
    VirtualPointActions
  }

  using do
    quote do
      import Plenario.Testing.DataCase
      alias Plenario.Repo
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Plenario.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Plenario.Repo, {:shared, self()})
    end

    # setup dependency tags
    tags =
      if not is_nil(tags[:virtual_date]) or not is_nil(tags[:virtual_point]) do
        merge_tag(tags, :field, true)
        |> merge_tag(:data_set, true)
        |> merge_tag(:user, true)
      else
        tags
      end

    tags =
      if tags[:field] do
        merge_tag(tags, :data_set, true)
        |> merge_tag(:user, true)
      else
        tags
      end

    tags =
      if tags[:data_set] do
        merge_tag(tags, :user, true)
      else
        tags
      end

    # build out the context
    context =
      %{}
      |> parse_tag(tags, :user, :create_user)
      |> parse_tag(tags, :data_set, :create_data_set)
      |> parse_tag(tags, :field, :create_field)
      |> parse_tag(tags, :virtual_date, :create_virtual_date)
      |> parse_tag(tags, :virtual_point, :create_virtual_point)

    # return the context for the tests
    {:ok, context}
  end

  defp merge_tag(tags, key, true) do
    case tags[key] do
      nil -> Map.put(tags, key, true)
      true -> Map.put(tags, key, true)
      _ -> tags
    end
  end

  # defp merge_tag(tags, key, value) when is_list(value) do
  #   case tags[key] do
  #     nil -> Map.put(tags, key, value)
  #     true -> Map.put(tags, key, value)
  #     kwlist -> Map.put(tags, key, Keyword.merge(kwlist, value))
  #   end
  # end

  defp parse_tag(context, tags, key, func) do
    case tags[key] do
      nil -> context
      true -> Map.put(context, key, apply(__MODULE__, func, [context]))
      opts -> Map.put(context, key, apply(__MODULE__, func, [context, opts]))
    end
  end

  def create_user(_ \\ %{}, opts \\ []) do
    params =
      [username: "Test User", email: "test@example.com", password: "password"]
      |> Keyword.merge(opts)

    {:ok, user} = UserActions.create(params)
    user
  end

  def create_data_set(%{user: user}, opts \\ []) do
    params =
      [user: user, name: "Test Data Set", src_url: "https://example.com/", src_type: "csv", socrata?: false]
      |> Keyword.merge(opts)

    {:ok, data_set} = DataSetActions.create(params)
    data_set
  end

  def create_field(%{data_set: data_set}, opts \\ []) do
    params =
      [data_set: data_set, name: "ID", type: "text"]
      |> Keyword.merge(opts)

    {:ok, field} = FieldActions.create(params)
    field
  end

  def create_virtual_date(%{data_set: data_set, field: field}, opts \\ []) do
    params =
      [data_set: data_set, yr_field: field]
      |> Keyword.merge(opts)

    {:ok, date} = VirtualDateActions.create(params)
    date
  end

  def create_virtual_point(%{data_set: data_set, field: field}, opts \\ []) do
    params =
      [data_set: data_set, loc_field: field]
      |> Keyword.merge(opts)

    params =
      if not is_nil(opts[:lon_field]) and not is_nil(opts[:lat_field]) do
        Keyword.delete(params, :loc_field)
      else
        params
      end

    {:ok, point} = VirtualPointActions.create(params)
    point
  end

  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Enum.reduce(opts, message, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
