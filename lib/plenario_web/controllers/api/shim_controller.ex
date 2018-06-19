defmodule PlenarioWeb.Api.ShimController do
  use PlenarioWeb, :api_controller
  import PlenarioWeb.Api.Utils, only: [halt_with: 3]

  @translations %{
    "dataset_name" => "slug"
  }

  @doc """
  Handles V1 API queries for dataset metadata records. Translate provided 
  parameters from V1 API keywords to V2 API keywords. Then defers to the 
  ListController for V2.
  """
  def datasets(conn, params) do
    PlenarioWeb.Api.ListController.call(conn, :get)
  end

  @doc """
  Handles V1 API queries for dataset records. Translate provided parameters 
  from V1 API keywords to V2 API keywords. Then defers to the DetailController
  for V2.
  """
  def detail(conn, %{"dataset_name" => _} = params) do
    %{conn | params: translate(conn.params)}
    |> PlenarioWeb.Api.DetailController.call(:get)
  end

  @doc """
  Params didn't come with a 'dataset_name'? VERBOTEN.
  """
  def detail(conn, _) do
    halt_with(conn, 422, "'dataset_name' is a required parameter!")
  end

  @doc """
  Takes a map, presumably containing keys that correspond to the V1 API, and
  converts them to keys that correspond to the V2 API. 
  
  Keys are translated using a map provided by @translations. 
  
  If a key isn't found in @translations, it is simply passed through. This is
  because the key could possibly correspond to a data set column, and will be
  validated dynamically.
  """
  def translate(params) when is_list(params) do
    translate(params, [])
  end

  @doc """
  Our params are a map? Convert it to a list and toss it back up.
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
  
  # todo
  If the key contains a dunder `__` operator. Convert both it and and the value
  to the V2 compliant `PARAM=OPERATOR:VALUE` format.
  """
  def translate([{key, value} | params], acc) do
    new_key_value_pair =
      case @translations[key] do
        nil -> {key, value}
        translated_key -> {translated_key, value}
      end

    translate(params, [new_key_value_pair | acc])
  end
end
