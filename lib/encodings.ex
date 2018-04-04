defimpl String.Chars, for: Map do
  def to_string(map) when is_map(map) do
    Poison.encode!(map)
  end
end


defimpl Poison.Encoder, for: Tuple do
  def encode(tuple, _options) do
    tuple
    |> Tuple.to_list
    |> Poison.encode!
  end
end
