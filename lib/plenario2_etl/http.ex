defmodule Plenario2Etl.Http do
  @moduledoc """
  Explicitly defines this application's http interface. With this module as a
  contract, we do not have to be tightly coupled to any one HTTP library and
  we can also provide an explicit mock.

  For information on this design pattern, check out [this blogpost](http://bl
  og.plataformatec.com.br/2015/10/mocks-and-explicit-contracts/) by Mr. Valim.
  """

  @http Application.get_env(:plenario2, :http)

  @doc """
  Issues a GET HTTP request.

  ## Examples

      iex> {:ok, %{
      ...>   body: body
      ...> }} = Plenario2Etl.Http.get("https://www.google.com")
      iex> body =~ "<!doctype html>"
      true

  """
  def get(url), do: @http.get(url)

  @doc """
  Issues a POST HTTP request.

  ## Examples

      iex> {:ok, %{
      ...>   status: status,
      ...> }} = Plenario2Etl.Http.post("https://www.google.com")
      iex> status == 200
      true

  """
  def post(url), do: @http.post(url)
end

defmodule HTTP.Behaviour do
  @callback get(url :: String.t()) :: {:ok, map}
  @callback post(url :: String.t(), data :: map) :: {:ok, map}
end

defmodule HTTP.Live do
  @behaviour HTTP.Behaviour

  def get(url) do
    %HTTPoison.Response{
      status_code: status,
      headers: headers,
      body: body
    } = HTTPoison.get!(url)

    {:ok, %{
      status: status,
      headers: headers,
      body: body
    }}
  end

  def post(url, data \\ %{}) do
    %HTTPoison.Response{
      status_code: status,
      headers: headers,
      body: body
    } = HTTPoison.post!(url, Poison.encode!(data))

    {:ok, %{
      status: status,
      headers: headers,
      body: body
    }}
  end
end

defmodule HTTP.Mock do
  @behaviour HTTP.Behaviour

  def get(_url) do
    {:ok, %{
      status: 200,
      headers: [],
      body: "<!doctype html>"
    }}
  end

  def post(_url, _data \\ %{}) do
    {:ok, %{
      status: 200,
      headers: [],
      body: "<!doctype html>"
    }}
  end
end
