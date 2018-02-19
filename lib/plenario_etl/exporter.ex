defmodule PlenarioEtl.Exporter do
  def export(job) do
    try do
      job
      |> generate_query()
      |> generate_stream()
      |> stream_to_storage()
      |> complete()
    catch :exit, code ->
      error(job)
    end
  end

  def generate_query(job) do
    job
  end

  def generate_stream(job) do
    job
  end

  def stream_to_storage(job) do
    job
  end

  def complete(job) do
    job
  end

  def error(job) do
    job
  end
end