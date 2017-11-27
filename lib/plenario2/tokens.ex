defmodule Plenario2.Tokens do
  def generate_token(size) do
    :crypto.strong_rand_bytes(size)
    |> Base.url_encode64()
    |> binary_part(0, size)
  end

  def generate_token() do
    generate_token(16)
  end
end
