defmodule PlenarioWeb.Api.Plugs do
  use PlenarioWeb, :api_controller
  alias Plug.Conn

  @doc """
  This function guarantees two outcomes. The returned `conn` will have a valid `page_size` in `params`, even if no
  `page_size` was provided. If a `page_size` was provided that is invalid (not a number, smaller than 0 or larger than
  the `:page_size_limit` opt), it breaks the pipeline early and returns a conn with an error.

  This is an implementation of the `call/2` method for building a plug. It's meant to be used in combination
  with the plug macro to be *plugged* (heh) into a request handling pipeline.

  ## Examples

      iex> use Plug.Builder
      iex> plug :with_page_size, default_page_size: 500, page_size_limit: 5000

      iex> conn = %Conn{params: %{}}
      iex> with_page_size(conn, default_page_size: 500, page_size_limit: 5000)
      %Conn{params: %{"page_size" => 500}}

      iex> conn = %Conn{params: %{"page_size" => "wrong"}}
      iex> with_page_size(conn, default_page_size: 500, page_size_limit: 5000)
      %Conn{status: 422}

      iex> conn = %Conn{params: %{"page_size" => "5001"}}
      iex> with_page_size(conn, default_page_size: 500, page_size_limit: 5000)
      %Conn{status: 422}

  """
  def with_page_size(conn = %Conn{params: %{"page_size" => page_size}}, opts) when is_integer(page_size) do
    case (opts[:page_size_limit] > page_size) and (page_size > 0) do
      true ->
        conn
      false ->
        conn
        |> put_req_header("accept", "application/vnd.api+json")  # Overwrite the request header to ask for json api content
        |> Explode.with(422, "Provided page_size '#{page_size}' must be between 0 and #{opts[:page_size_limit]}")
    end
  end

  @doc """
  "page_size" not an integer? Attempt to parse it to an integer and toss it back up. If parsing fails, halt the
  request pipeline and inform the user.
  """
  def with_page_size(conn = %Conn{params: %{"page_size" => page_size}}, opts) do
    case Integer.parse(page_size) do
      {parsed_page_size, _} ->
        with_page_size(%{conn | params: Map.put(conn.params, "page_size", parsed_page_size)}, opts)
      :error ->
        conn
        |> put_req_header("accept", "application/vnd.api+json")  # Overwrite the request header to ask for json api content
        |> Explode.with(422, "Provided page_size '#{page_size}' must be a number.")
    end
  end

  @doc """
  No "page_size" specified? Assign the default and toss it back up.
  """
  def with_page_size(conn, opts) do
    with_page_size(%{conn | params: Map.put(conn.params, "page_size", opts[:default_page_size])}, opts)
  end
end
