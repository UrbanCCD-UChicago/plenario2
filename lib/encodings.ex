defimpl String.Chars, for: Map do
  def to_string(map) when is_map(map) do
    Poison.encode!(map)
  end
end
