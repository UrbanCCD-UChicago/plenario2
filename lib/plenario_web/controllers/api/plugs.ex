defmodule PlenarioWeb.Api.Plugs do
  import Plug.Conn, only: [put_req_header: 3]
  alias Plug.Conn

  @doc """
  This function guarantees two outcomes. The returned `conn` will have a valid `page_size` in `params`, even if no
  `page_size` was provided. If a `page_size` was provided that is invalid (not a number, smaller than 0 or larger than
  the `:page_size_limit` opt), it breaks the pipeline early and returns a conn with an error.

  This is an implementation of the `call/2` method for building a plug. It's meant to be used in combination
  with the plug macro to be *plugged* (heh) into a request handling pipeline.

  ## Examples

      iex> use Plug.Builder
      iex> plug :check_page_size, default_page_size: 500, page_size_limit: 5000

      iex> conn = %Conn{params: %{}}
      iex> check_page_size(conn, default_page_size: 500, page_size_limit: 5000)
      %Conn{params: %{"page_size" => 500}}

      iex> conn = %Conn{params: %{"page_size" => "wrong"}}
      iex> check_page_size(conn, default_page_size: 500, page_size_limit: 5000)
      %Conn{status: 422}

      iex> conn = %Conn{params: %{"page_size" => "5001"}}
      iex> check_page_size(conn, default_page_size: 500, page_size_limit: 5000)
      %Conn{status: 422}

  """
  def check_page_size(conn = %Conn{params: %{"page_size" => page_size}}, opts) when is_integer(page_size) do
    case (opts[:page_size_limit] > page_size) and (page_size > 0) do
      true ->
        conn
      false ->
        conn
        # Even if the request is asking for something else, we only serve json so we overwrite the
        # header of the incoming request. This will definitely have to be changed later if we want
        # to serve more than one media type. For most browsers, their default accept header prefers
        # xml, and this can lead to some weirdly formatted errors.
        |> put_req_header("accept", "application/vnd.api+json")
        |> Explode.with(422, "Provided page_size '#{page_size}' must be between 0 and #{opts[:page_size_limit]}")
    end
  end

  @doc """
  "page_size" not an integer? Attempt to parse it to an integer and toss it back up. If parsing fails, halt the
  request pipeline and inform the user.
  """
  def check_page_size(conn = %Conn{params: %{"page_size" => page_size}}, opts) do
    case Integer.parse(page_size) do
      {parsed_page_size, _} ->
        check_page_size(%{conn | params: Map.put(conn.params, "page_size", parsed_page_size)}, opts)
      :error ->
        conn
        # Even if the request is asking for something else, we only serve json so we overwrite the
        # header of the incoming request. This will definitely have to be changed later if we want
        # to serve more than one media type. For most browsers, their default accept header prefers
        # xml, and this can lead to some weirdly formatted errors.
        |> put_req_header("accept", "application/vnd.api+json")
        |> Explode.with(422, "Provided page_size '#{page_size}' must be a number.")
    end
  end

  @doc """
  No "page_size" specified? Assign the default and toss it back up.
  """
  def check_page_size(conn, opts) do
    check_page_size(%{conn | params: Map.put(conn.params, "page_size", opts[:default_page_size])}, opts)
  end

  @doc """
  This function guarantees two outcomes. The returned `conn` will have a valid `page` in `params`, even if no
  `page` was provided. If a `page` was provided that is invalid (not a number, negative), it breaks the pipeline
  early and returns a conn with an error.

  This is an implementation of the `call/2` method for building a plug. It's meant to be used in combination
  with the plug macro to be *plugged* (heh) into a request handling pipeline.

  ## Examples

      iex> use Plug.Builder
      iex> plug :check_page

      iex> conn = %Conn{params: %{}}
      iex> check_page(conn)
      %Conn{params: %{"page" => 2}}

      iex> conn = %Conn{params: %{"page" => "wrong"}}
      iex> check_page(conn)
      %Conn{status: 422}

      iex> conn = %Conn{params: %{"page" => "-100"}}
      iex> check_page(conn)
      %Conn{status: 422}

  """
  def check_page(conn = %Conn{params: %{"page" => page}}, _) when is_integer(page) and page > 0, do: conn
  def check_page(conn = %Conn{params: %{"page" => page}}, _) when is_integer(page) and page <= 0 do
    # Even if the request is asking for something else, we only serve json so we overwrite the
    # header of the incoming request. This will definitely have to be changed later if we want
    # to serve more than one media type. For most browsers, their default accept header prefers
    # xml, and this can lead to some weirdly formatted errors.
    conn
    |> put_req_header("accept", "application/vnd.api+json")
    |> Explode.with(422, "Provided page '#{page}' must be positive.")
  end

  @doc """
  "page" is a float? Convert it to an integer and toss it back up.
  """
  def check_page(conn = %Conn{params: %{"page" => page}}, opts) when is_float(page) do
    page_float = round(page)
    check_page(%{conn | params: Map.put(conn.params, "page", page_float)}, opts)
  end

  @doc """
  "page" not an integer? Attempt to parse it to an integer and toss it back up. If parsing fails, halt the
  request pipeline and inform the user.
  """
  def check_page(conn = %Conn{params: %{"page" => page}}, opts) do
    case Integer.parse(page) do
      {parsed_page, _} ->
        check_page(%{conn | params: Map.put(conn.params, "page", parsed_page)}, opts)
      :error ->
        conn
        # Even if the request is asking for something else, we only serve json so we overwrite the
        # header of the incoming request. This will definitely have to be changed later if we want
        # to serve more than one media type. For most browsers, their default accept header prefers
        # xml, and this can lead to some weirdly formatted errors.
        |> put_req_header("accept", "application/vnd.api+json")
        |> Explode.with(422, "Provided page '#{page}' must be a number.")
    end
  end

  @doc """
  No "page" specified? Assign the default and toss it back up.
  """
  def check_page(conn, opts) do
    check_page(%{conn | params: Map.put(conn.params, "page", 1)}, opts)
  end
end
