defmodule Plenario.FieldGuesserTest do
  use Plenario.Testing.DataCase

  alias Plenario.Actions.{
    DataSetActions,
    UniqueConstraintActions,
    DataSetFieldActions,
    VirtualPointFieldActions,
    UserActions
  }

  alias PlenarioEtl.Actions.EtlJobActions

  import Plenario.FieldGuesser
  import Mock

  @doc """
  This helper function replaces the call to HTTPoison.get using the `stream_to`
  option. It sends the caller aynchronous chunks.
  """
  def mock_csv_data_request(_, _, opts) do
    stream_to = opts[:stream_to]
    send(stream_to, %HTTPoison.AsyncStatus{id: self(), code: 200})
    send(stream_to, %HTTPoison.AsyncChunk{
      chunk: """
      pk,datetime,location,data
      1,2017-01-01T00:00:00,"(0, 1)",crackers
      2,2017-02-02T00:00:00,"(0, 2)",and
      3,2017-03-03T00:00:00,"(0, 3)",cheese
      0,2017-01-01T00:00:00,0,crackers
      """,
      id: self()
    })

    send(stream_to, %HTTPoison.AsyncEnd{id: self()})

    {:ok, %HTTPoison.AsyncResponse{id: self()}}
  end

  @doc """
  This helper function replaces the call to HTTPoison.get using the `stream_to`
  option. It sends the caller aynchronous chunks.
  """
  def mock_tsv_data_request(_, _, opts) do
    stream_to = opts[:stream_to]
    send(stream_to, %HTTPoison.AsyncStatus{id: self(), code: 200})
    send(stream_to, %HTTPoison.AsyncChunk{
      id: self(),
      chunk: """
      pk\tdatetime\tlocation\tdata
      1\t2017-01-01T00:00:00\t"(0, 1)"\tcrackers
      2\t2017-02-02T00:00:00\t"(0, 2)"\tand
      3\t2017-03-03T00:00:00\t"(0, 3)"\tcheese
      """
    })

    send(stream_to, %HTTPoison.AsyncEnd{id: self()})

    {:ok, %HTTPoison.AsyncResponse{id: self()}}
  end

  @doc """
  This helper function replaces the call to HTTPoison.get!.
  """
  def mock_json_data_request(_) do
    %HTTPoison.Response{
      body: """
      [{
        "pk": 1,
        "datetime": "2017-01-01T00:00:00",
        "location": "(0, 1)",
        "data": "crackers"
      },{
        "pk": 2,
        "datetime": "2017-01-02T00:00:00",
        "location": "(0, 2)",
        "data": "and"
      },{
        "pk": 3,
        "datetime": "2017-01-03T00:00:00",
        "location": "(0, 3)",
        "data": "cheese"
      }]
      """
    }
  end

  setup context do
    Plenario.ModelRegistry.clear()

    meta = context.meta
    {:ok, _} = UserActions.create("Trusted User", "trusted@example.com", "password")
    {:ok, pk_field} = DataSetFieldActions.create(meta.id, "pk", "integer")
    {:ok, _} = DataSetFieldActions.create(meta.id, "datetime", "timestamptz")
    {:ok, loc_field} = DataSetFieldActions.create(meta.id, "location", "text")
    {:ok, _} = DataSetFieldActions.create(meta.id, "data", "text")
    {:ok, _} = UniqueConstraintActions.create(meta.id, [pk_field.id, loc_field.id])
    {:ok, _} = EtlJobActions.create(meta.id)
    VirtualPointFieldActions.create(meta.id, loc_field: loc_field)
    DataSetActions.up!(meta)

    %{meta: meta}
  end

  test "guess_field_types!/1 of csv", %{meta: meta} do
    with_mock HTTPoison, get: &mock_csv_data_request/3 do
      assert guess_field_types!(meta) == %{
        "pk" => "integer",
        "datetime" => "timestamptz",
        "location" => "text",
        "data" => "text"
      }
    end
  end

  test "guess_field_types!/1 of tsv", %{meta: meta} do
    {:ok, meta} = Plenario.Actions.MetaActions.update(meta, source_type: "tsv")
    with_mock HTTPoison, get: &mock_tsv_data_request/3 do
      assert guess_field_types!(meta) == %{
        "pk" => "integer",
        "datetime" => "timestamptz",
        "location" => "text",
        "data" => "text"
      }
    end
  end

  test "guess_field_types!/1 of json", %{meta: meta} do
    {:ok, meta} = Plenario.Actions.MetaActions.update(meta, source_type: "json")
    with_mock HTTPoison, get!: &mock_json_data_request/1 do
      assert guess_field_types!(meta) == %{
        "pk" => "integer",
        "datetime" => "timestamptz",
        "location" => "text",
        "data" => "text"
      }
    end
  end

  test "guess/1" do
    assert guess("true") == "boolean"
    assert guess("7") == "integer"
    assert guess("0.0") == "float"
    assert guess("01/01/2000") == "timestamptz"
    assert guess(~s/{"foo": "bar"}/) == "jsonb"
  end

  test "boolean?/1" do
    assert boolean?(true)
    assert boolean?(false)
    assert boolean?("true")
    assert boolean?("false")
    assert boolean?("t")
    assert boolean?("f")
  end

  test "integer?/1" do
    assert integer?(0)
    assert integer?(0.0) == false
    assert integer?("7")
    assert integer?("9.0") == false
  end

  test "float?/1" do
    assert float?(0) == false
    assert float?(0.0)
    assert float?("0") == false
    assert float?("0.0")
  end

  test "date?/1" do
    assert date?("01/01/2000")
    assert date?("01/01/2000 01:01:01 AM")
    assert date?("01/01/2000 01:01:01 PM")
    assert date?("01-01-2000")
    assert date?("01-01-2000 01:01:01 PM")
    assert date?("01-01-2000 01:01:01 PM")
    assert date?("2000-01-01 01:01:01")
    assert date?("2000-01-01 01:01:01.0000")

    assert date?("09-01749218") == false
    assert date?("09017492-18") == false
    assert date?("0901749218") == false
    assert date?("(000) 000-0000") == false
  end

  test "json?/1" do
    assert json?("{}")
    assert json?("[]")
    assert json?(~s/{"foo": "bar"}/)
    assert json?(~s/{"foo": {"bar": "baz"}}/)
    assert json?(~s/[{"foo": {"bar": "baz"}}]/)
  end
end
