defmodule Plenario.Etl.Downloader do
  require Logger

  alias Exsoda.Reader

  alias Plenario.{
    DataSet,
    FieldActions
  }

  @socrata_page 50_000

  def download(%DataSet{} = ds, limit \\ nil) do
    path = make_path(ds)

    Logger.info("downloading #{ds.name}")
    Logger.debug("writing contents to #{path}")

    :ok = do_download(ds, path, limit)
    path
  end

  defp make_path(%DataSet{slug: name, src_type: ext}) do
    path = "/tmp/#{name}.#{ext}"

    if File.exists?(path), do: File.rm!(path)
    File.touch!(path)

    path
  end

  # SOCRATA

  defp do_download(%DataSet{soc_domain: domain, soc_4x4: fourby} = ds, path, _) when not is_nil(domain) and not is_nil(fourby) do
    Logger.debug("using exsoda to download #{ds.name}")

    fields =
      FieldActions.list(for_data_set: ds)
      |> Enum.map(& &1.col_name)

    # build the initial query
    query =
      Reader.query(fourby, domain: domain)
      |> Reader.select(fields)
      |> Reader.order(":created_at DESC")
      |> Reader.limit(@socrata_page)

    # get a file handler and dump the opening bracket to it
    fh = File.open!(path, [:append, :utf8])

    # download in pages
    download_socrata(ds, query, fh, path)
  end

  # WEB RESOURCE

  defp do_download(%DataSet{src_url: url} = ds, path, limit) when not is_nil(url) do
    fh = File.open!(path, [:append, :utf8])

    %HTTPoison.AsyncResponse{id: id} = HTTPoison.get!(url, %{}, stream_to: self())
    Logger.debug("using async httpoison to download #{ds.name}", id: id)
    receive_chunks(id, limit, fh)
  end

  # Socrata Helpers

  defp download_socrata(%DataSet{latest_import: nil}, query, fh, path),
    do: page_socrata(Reader.limit(query, @socrata_page), fh, path, 0)

  defp download_socrata(%DataSet{latest_import: latest}, query, fh, path) do
    latest = Timex.format!(latest, "%Y-%m-%dT%H:%M:%S", :strftime)

    query =
      query
      |> Reader.where(":updated_at >= '#{latest}'")

    page_socrata(query, fh, path, 0)
  end

  defp page_socrata(query, fh, path, offset) do
    query =
      query
      |> Reader.offset(offset)

    Logger.debug("paged socrata query is #{inspect(query)}")

    {:ok, stream} = Reader.run(query)

    rows =
      stream
      |> Enum.map(fn record ->
        record
        |> Enum.map(fn {k, v} -> {:"#{k}", v} end)
        |> Enum.into(%{})
      end)

    num_rows = length(rows)
    Logger.debug("got #{num_rows} records")

    content = Jason.encode!(rows)
    IO.binwrite(fh, "#{content}\n")

    case num_rows < @socrata_page do
      true ->
        File.close(fh)

      false ->
        page_socrata(query, fh, path, offset + @socrata_page)
    end
  end

  # Web Resource Helpers

  defp receive_chunks(id, limit, fh), do: receive_chunks(id, limit, 0, fh)
  defp receive_chunks(_id, limit, count, fh) when is_integer(limit) and count >= limit, do: File.close(fh)
  defp receive_chunks(id, limit, count, fh) do
    receive do
      %HTTPoison.AsyncStatus{id: ^id, code: 200} ->
        Logger.debug("response status 200 Ok", id: id)
        receive_chunks(id, limit, count, fh)

      %HTTPoison.AsyncHeaders{id: ^id, headers: headers} ->
        Logger.debug("response headers #{inspect(headers)}", id: id)
        receive_chunks(id, limit, count, fh)

      %HTTPoison.AsyncChunk{id: ^id, chunk: chunk} ->
        Logger.debug("writing async chunk", id: id)
        IO.binwrite(fh, chunk)
        receive_chunks(id, limit, count + 1, fh)

      %HTTPoison.AsyncEnd{id: ^id} ->
        Logger.debug("response ended", id: id)
        :ok
    end
  end
end
