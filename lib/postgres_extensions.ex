Postgrex.Types.define(
  Plenario.PostGisTypes,
  [Geo.PostGIS.Extension] ++ Ecto.Adapters.Postgres.extensions(),
  json: Poison
)

defmodule Plenario.TsRange do
  @moduledoc """
  """

  alias Plenario.TsRange

  alias Postgrex.Range

  @typedoc """
  """
  @type t :: %__MODULE__{
          lower: NaiveDateTime.t(),
          upper: NaiveDateTime.t(),
          lower_inclusive: boolean,
          upper_inclusive: boolean
        }

  defstruct lower: nil,
            upper: nil,
            lower_inclusive: true,
            upper_inclusive: true

  @doc """
  """
  @spec new(NaiveDateTime.t(), NaiveDateTime.t(), boolean, boolean) :: TsRange.t()
  def new(lower, upper, lower_inclusive \\ true, upper_inclusive \\ true) do
    %TsRange{
      lower: from_erl(lower),
      upper: from_erl(upper),
      lower_inclusive: lower_inclusive,
      upper_inclusive: upper_inclusive
    }
  end

  @doc """
  """
  @spec from_postgrex(Range.t()) :: TsRange.t()
  def from_postgrex(range) do
    new(
      from_erl(range.lower),
      from_erl(range.upper),
      range.lower_inclusive,
      range.upper_inclusive
    )
  end

  @doc """
  """
  @spec to_postgrex(TsRange.t()) :: Range.t()
  def to_postgrex(range) do
    %Range{
      lower: to_erl(range.lower),
      upper: to_erl(range.upper),
      lower_inclusive: range.lower_inclusive,
      upper_inclusive: range.upper_inclusive
    }
  end

  defp to_erl({ymd, {h, m, s}}), do: {ymd, {h, m, s, 0}}

  defp to_erl({{_, _}, {_, _, _, _}} = erl), do: erl

  defp to_erl(%NaiveDateTime{} = d) do
    {ymd, {h, m, s}} = NaiveDateTime.to_erl(d)
    {ymd, {h, m, s, 0}}
  end

  defp to_erl(_), do: nil

  defp from_erl(%NaiveDateTime{} = ndt), do: ndt

  defp from_erl({{y, m, d}, {h, i, s}}) do
    case NaiveDateTime.new(y, m, d, h, i, s, {0, 0}) do
      {:ok, n} -> n
      _ -> nil
    end
  end

  defp from_erl({{y, m, d}, {h, i, s, u}}) do
    case NaiveDateTime.new(y, m, d, h, i, s, {u, 0}) do
      {:ok, n} -> n
      _ -> nil
    end
  end

  defp from_erl(_), do: nil

  defimpl String.Chars, for: Plenario.TsRange do
    @spec to_string(TsRange.t()) :: String.t()
    def to_string(r) do
      lb =
        case r.lower_inclusive do
          true -> "["
          false -> "("
        end

      ub =
        case r.upper_inclusive do
          true -> "]"
          false -> ")"
        end

      lo =
        case r.lower do
          nil -> ""
          _ -> "#{r.lower}"
        end

      hi =
        case r.upper do
          nil -> ""
          _ -> "#{r.upper}"
        end

      "#{lb}#{lo}, #{hi}#{ub}"
    end
  end

  defimpl Poison.Encoder, for: Plenario.TsRange do
    def encode(range, opts) do
      Poison.Encoder.Map.encode(
        %{
          lower_inclusive: range.lower_inclusive,
          upper_inclusive: range.upper_inclusive,
          lower: Timex.format!(range.lower, "%Y-%m-%dT%H:%M:%S", :strftime),
          upper: Timex.format!(range.upper, "%Y-%m-%dT%H:%M:%S", :strftime)
        },
        opts
      )
    end
  end

  defimpl Poison.Decoder, for: Plenario.TsRange do
    def decode(tasks, _opts) do
      Map.update!(tasks, :lower, &Timex.parse!(&1, "%Y-%m-%dT%H:%M:%S", :strftime))
      |> Map.update!(:upper, &Timex.parse!(&1, "%Y-%m-%dT%H:%M:%S", :strftime))
    end
  end

  @behaviour Ecto.Type

  @doc false
  def type, do: :tsrange

  @doc false
  def cast(nil), do: {:ok, nil}
  def cast(%Range{} = r), do: {:ok, r}
  def cast(%TsRange{} = r), do: {:ok, to_postgrex(r)}
  def cast(_), do: :error

  @doc false
  def load(nil), do: {:ok, nil}
  def load(%Range{} = r), do: {:ok, from_postgrex(r)}
  def load(%TsRange{} = r), do: {:ok, r}
  def load(_), do: :error

  @doc false
  def dump(nil), do: {:ok, nil}
  def dump(%Range{} = r), do: {:ok, r}
  def dump(%TsRange{} = r), do: {:ok, to_postgrex(r)}
  def dump(_), do: :error
end

defmodule Plenario.Extensions.TsRange do
  @moduledoc false

  use Bitwise, only_operators: true

  import Postgrex.BinaryUtils, warn: false

  @behaviour Postgrex.SuperExtension

  @range_empty 0x01
  @range_lb_inc 0x02
  @range_ub_inc 0x04
  @range_lb_inf 0x08
  @range_ub_inf 0x10

  def init(_), do: nil

  def matching(_), do: [type: "tsrange"]

  def format(_), do: :super_binary

  def oids(%Postgrex.TypeInfo{base_type: oid}, _), do: [oid]

  def encode(_) do
    quote location: :keep do
      %Plenario.TsRange{lower: lower, upper: upper} = range, [oid], [type] ->
        # encode_value/2 defined by TypeModule
        lower = encode_value(lower, type)
        upper = encode_value(upper, type)
        unquote(__MODULE__).encode(range, oid, lower, upper)

      other, _, _ ->
        raise ArgumentError, Postgrex.Utils.encode_msg(other, Postgrex.Range)
    end
  end

  def decode(_) do
    quote location: :keep do
      <<len::int32, binary::binary-size(len)>>, [oid], [type] ->
        <<flags, data::binary>> = binary
        # decode_list/2 and @null defined by TypeModule
        case decode_list(data, type) do
          [upper, lower] ->
            unquote(__MODULE__).decode(flags, oid, [lower, upper], @null)

          empty_or_one ->
            unquote(__MODULE__).decode(flags, oid, empty_or_one, @null)
        end
    end
  end

  # helpers

  def encode(
        %Plenario.TsRange{lower_inclusive: lower_inc, upper_inclusive: upper_inc},
        _oid,
        lower,
        upper
      ) do
    flags = 0

    {flags, bin} =
      if lower == <<-1::int32>> do
        {flags ||| @range_lb_inf, ""}
      else
        {flags, lower}
      end

    {flags, bin} =
      if upper == <<-1::int32>> do
        {flags ||| @range_ub_inf, bin}
      else
        {flags, [bin | upper]}
      end

    flags =
      if lower_inc do
        flags ||| @range_lb_inc
      else
        flags
      end

    flags =
      if upper_inc do
        flags ||| @range_ub_inc
      else
        flags
      end

    [<<IO.iodata_length(bin) + 1::int32>>, flags | bin]
  end

  def decode(flags, _oid, [], null) when (flags &&& @range_empty) != 0 do
    %Plenario.TsRange{lower: null, upper: null}
  end

  def decode(flags, _oid, elems, null) do
    {lower, elems} =
      if (flags &&& @range_lb_inf) != 0 do
        {null, elems}
      else
        [lower | rest] = elems
        {lower, rest}
      end

    {upper, []} =
      if (flags &&& @range_ub_inf) != 0 do
        {null, elems}
      else
        [upper | rest] = elems
        {upper, rest}
      end

    lower_inclusive = (flags &&& @range_lb_inc) != 0
    upper_inclusive = (flags &&& @range_ub_inc) != 0

    %Plenario.TsRange{
      lower: lower,
      upper: upper,
      lower_inclusive: lower_inclusive,
      upper_inclusive: upper_inclusive
    }
  end
end
