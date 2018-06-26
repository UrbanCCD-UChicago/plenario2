defmodule PlenarioWeb.Api.ShimController do
  use PlenarioWeb, :api_controller
  import PlenarioWeb.Api.Utils, only: [halt_with: 3]
  alias Plenario.Actions.MetaActions
  alias Plenario.Repo

  @translations %{
    "dataset_name" => "slug"
  }

  @doc """
  Handles V1 API queries for dataset metadata records. Translate provided
  parameters from V1 API keywords to V2 API keywords. Then defers to the
  ListController for V2.
  """
  def datasets(conn, _) do
    %{conn | params: translate(conn.params)}
    |> PlenarioWeb.Api.ListController.call(:get)
  end

  @doc """
  Handles V1 API queries for dataset records. Translate provided parameters
  from V1 API keywords to V2 API keywords. Then defers to the DetailController
  for V2.
  """
  def detail(conn, %{"dataset_name" => _}) do
    %{conn | params: translate(conn.params)}
    |> obs_date_to_first_datetime_field()
    |> PlenarioWeb.Api.DetailController.call(:get)
  end

  @doc """
  Params didn't come with a 'dataset_name'? VERBOTEN.
  """
  def detail(conn, _) do
    halt_with(conn, 422, "'dataset_name' is a required parameter!")
  end

  @doc """

  """
  def get_obs_date_for_slug(slug) do
    meta = MetaActions.get(slug, with_fields: true)
    Enum.find(meta.fields, fn field -> field.type == "timestamptz" end)
  end

  @doc """

  """
  def get_geom_for_slug(conn) do
    meta = MetaActions.get(slug, with_fields: true)
    Enum.find(meta.fields, fn field -> field.type == "geom" end)
  end

  @doc """
  Takes a map, presumably containing keys that correspond to the V1 API, and
  converts them to keys that correspond to the V2 API.

  Keys are translated using a map provided by @translations.

  If a key isn't found in @translations, it is simply passed through. This is
  because the key could possibly correspond to a data set column, and will be
  validated dynamically.

  ## Examples

      iex> params = [{"foo__gt", "bar"}, {"baz__eq", "buzz"}]
      iex> translate(params)
      [{"foo", "gt:bar"}, {"baz", "eq:buzz"}]

  """
  def translate(params) when is_list(params) do
    translate(params, [])
  end

  @doc """
  Our params are a map? Convert it to a list and toss it back up.

  ## Examples

      iex> params = %{"foo_gt" => "bar", "baz__eq" => "buzz"}
      iex> translate(params)
      [{"foo", "gt:bar"}, {"baz", "eq:buzz"}]

  """
  def translate(params) when is_map(params) do
    params
    |> Map.to_list()
    |> translate()
  end

  @doc """
  Have we run out of params to translate? Noice, we've hit our base case. Take
  our collection of tuples in the `acc`umulator and return a map.
  """
  def translate([], acc) do
    Map.new(acc)
  end

  @doc """
  Takes a collection of 2n tuples where the first value represents a key, and
  the second value represents a value.

  If the key corresponds to a V1 API keyword, convert it. Otherwise just pass
  the tuple along into the `acc`umulator.

  If the key contains a dunder `__` operator. Convert both it and and the value
  to the V2 compliant `PARAM=OPERATOR:VALUE` format.

  ## Examples

      iex> params = [
      ...>   {"dataset_name", "dset"},
      ...>   {"foo__gt", "bar"},
      ...>   {"baz__eq", "buzz"}
      ...> ]
      iex> translate(params)
      [{"slug", "dset"}, {"foo", "gt:bar"}, {"baz", "eq:buzz"}]

  """
  def translate([{key, value} | params], acc) do
    param =
      {key, value}
      |> format_key_value_pair()
      |> translate_key_value_pair()
    translate(params, [param | acc])
  end

  @doc """
  Formats V1 style queries as V2 style queries if applicable.

  ## Examples

      iex> format_key_value_pair({"foo__gt", "bar"})
      {"foo", "gt:bar"}

  """
  def format_key_value_pair({key, value}) do
    case String.split(key, "__", parts: 2) do
      [column, operator] -> {column, operator <> ":" <> value}
      [column] -> {column, value}
    end
  end

  @doc """
  Takes key value pairs and translates the coverts the V1 API key to a V2 API
  key if applicable.

  Makes use of the `@translations` map provided by this module.

  ## Examples

      iex> translate_key_value_pair({"dataset_name", "foo"})
      {"slug", "foo"}

  """
  def translate_key_value_pair({key, value}) do
    case @translations[key] do
      nil -> {key, value}
      translated_key -> {translated_key, value}
    end
  end
end
