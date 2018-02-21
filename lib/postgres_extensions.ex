Postgrex.Types.define(
  Plenario.PostGisTypes,
  [Geo.PostGIS.Extension] ++ Ecto.Adapters.Postgres.extensions(),
  json: Poison
)

defmodule Plenario.TsTzRange do
  @behaviour Ecto.Type

  def type(), do: :tstzrange

  def cast(nil), do: {:ok, nil}
  def cast([lower, upper]), do: {:ok, [lower, upper]}
  def cast(_), do: :error

  def load(%Postgrex.Range{lower: lower, upper: upper}) do
    lower = to_datetime(lower)
    upper = to_datetime(upper)

    case {lower, upper} do
      {nil, nil} -> {:ok, [nil, nil]}
      {{:ok, lower}, {:ok, upper}} -> {:ok, [lower, upper]}
      _ -> :error
    end
  end
  def load(_), do: :error

  def dump([lower, upper]) do
    {
      :ok,
      %Postgrex.Range{
        lower: from_datetime(lower),
        upper: from_datetime(upper),
        upper_inclusive: true
      }
    }
  end
  def dump(_), do: :error

  defp to_datetime(nil), do: nil
  defp to_datetime({{y, m, d}, {h, mm, s, ms}}) do
    {status, dt, _} = DateTime.from_iso8601("#{y}-#{lp(m)}-#{lp(d)}T#{lp(h)}:#{lp(mm)}:#{lp(s)}.#{ms}Z")
    case status do
      :ok -> {:ok, dt}
      _ -> :error
    end
  end

  defp from_datetime(nil), do: nil
  defp from_datetime(dt) do
    {
      {dt.year, dt.month, dt.day},
      {dt.hour, dt.minute, dt.second, elem(dt.microsecond, 0)}
    }
  end

  defp lp(number) do
    if number >= 10 do
      "#{number}"
    else
      "0#{number}"
    end
  end
end

defmodule Plenario.ForgivingDatetime do
  @behaviour Ecto.Type

  def type(), do: :timestamptz

  @us_dt_string ~r/(?P<mo>\d{1,2})\/(?P<d>\d{1,2})\/(?P<y>\d{4}).?(?P<h>\d{2})?\:?(?P<mi>\d{2})?\:?(?P<s>\d{2})?/

  @iso_dt_string ~r/(?P<y>\d{4})-(?P<mo>\d{2})-(?P<d>\d{2}).?(?P<h>\d{2})?\:?(?P<mi>\d{2})?\:?(?P<s>\d{2})?/

  def cast(nil), do: {:ok, nil}
  def cast(value) when is_bitstring(value) do
    case Regex.match?(@iso_dt_string, value) do
      true -> {:ok, value}
      false ->
        case Regex.match?(@us_dt_string, value) do
          true -> {:ok, value}
          false -> :error
        end
    end
  end
  def cast(_), do: :error

  def load({{y, m, d}, {h, mm, s, _}}) do 
    {:ok, NaiveDateTime.from_erl!({{y, m, d}, {h, mm, s}})}
  end

  def dump(nil), do: {:ok, nil}
  def dump(value) do
    case Regex.scan(@iso_dt_string, value, capture: :all_names) do
      [[day, hr, min, mon, sec, yr] | _] ->
        parse_bits(day, hr, min, mon, sec, yr)

      _ ->
        case Regex.scan(@us_dt_string, value, capture: :all_names) do
          [[day, hr, min, mon, sec, yr] | _] ->
            parse_bits(day, hr, min, mon, sec, yr)

          _ ->
            {:ok, nil}
        end
    end
  end

  defp parse_bits(day, hr, min, mon, sec, yr) do
    day = parse_int_str(day)
    hr = parse_int_str(hr)
    min = parse_int_str(min)
    mon = parse_int_str(mon)
    sec = parse_int_str(sec)
    yr = parse_int_str(yr)

    case yr != 0 and mon != 0 and day != 0 do
      true -> {:ok, {{yr, mon, day}, {hr, min, sec, 0}}}
      false -> {:ok, nil}
    end
  end

  defp parse_int_str(value) do
    case Integer.parse(value) do
      :error -> 0
      {num, _} -> num
    end
  end
end

defmodule Plenario.Jsonb do
  @behaviour Ecto.Type

  def type(), do: :jsonb

  def cast(value), do: {:ok, value}

  def load(value), do: {:ok, value}

  def dump(value), do: {:ok, value}
end
