defmodule Plenario.ViewModelRegistry do
  use GenServer

  alias Plenario.{
    DataSet,
    DataSetActions
  }

  @type_map %{
    "boolean" => :boolean,
    "float" => :float,
    "integer" => :integer,
    "text" => :string,
    "timestamp" => :naive_datetime,
    "jsonb" => :map,
    "geometry" => Geo.Geometry
  }

  @pid __MODULE__
  @name @pid

  @clean_state %{}

  # init

  def start_link, do: GenServer.start_link(@pid, :ok, name: @name)

  def init(:ok), do: {:ok, @clean_state}

  # client api

  def lookup(%DataSet{slug: slug}), do: lookup(slug)
  def lookup(slug) when is_binary(slug), do: GenServer.call(@pid, {:lookup, slug})

  def clear, do: GenServer.cast(@pid, :clear)

  # callbacks

  def handle_call({:lookup, slug}, _sender, models) do
    models =
      case Map.has_key?(models, slug) do
        true -> models
        false -> Map.merge(models, register(slug))
      end

    {:reply, Map.fetch!(models, slug), models}
  end

  def handle_cast(:clear, state) do
    Map.values(state)
    |> Enum.each(fn module ->
      :code.delete(module)
      :code.purge(module)
    end)

    {:noreply, @clean_state}
  end

  # model building

  defp register(slug) do
    data_set = DataSetActions.get! slug,
      with_fields: true,
      with_virtual_dates: true,
      with_virtual_points: true

    module = String.to_atom("ViewModels.#{data_set.view_name}")

    fields =
      data_set.fields
      |> Enum.map(fn field ->
        col_atom = String.to_atom(field.col_name)
        col_type = Map.fetch!(@type_map, field.type)
        {col_atom, col_type}
      end)

    points = Enum.map(data_set.virtual_points, & {String.to_atom(&1.col_name), Geo.Geometry})
    dates = Enum.map(data_set.virtual_dates, & {String.to_atom(&1.col_name), :naive_datetime})

    create_module(module, data_set.view_name, fields ++ points ++ dates)

    %{
      "#{data_set.id}" => module,
      data_set.slug => module
    }
  end

  defp create_module(module, view, fields) do
    Module.create(module, quote do
      use Ecto.Schema
      @primary_key false
      schema unquote(view) do
        unquote(for {name, type} <- fields do
          quote do
            field unquote(name), unquote(type), default: nil
          end
        end)
      end
    end, Macro.Env.location(__ENV__))
  end
end
