defmodule Plenario.TableModelRegistry do
  use GenServer

  alias Plenario.{
    DataSet,
    DataSetActions
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

    module = String.to_atom("TableModels.#{data_set.table_name}")

    fields =
      data_set.fields
      |> Enum.map(& String.to_atom(&1.col_name))

    create_module(module, data_set.table_name, fields)

    %{
      "#{data_set.id}" => module,
      data_set.slug => module
    }
  end

  defp create_module(module, table, fields) do
    Module.create(module, quote do
      use Ecto.Schema
      @primary_key false
      schema unquote(table) do
        unquote(for name <- fields do
          quote do
            field unquote(name), :string, default: nil
          end
        end)
      end
    end, Macro.Env.location(__ENV__))
  end
end
