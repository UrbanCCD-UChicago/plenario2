defimpl CSV.Encode, for: Map do
  def encode(map, env \\ []) when is_map(map) do
    Poison.encode!(map)
  end
end
