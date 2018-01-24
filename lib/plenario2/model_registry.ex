defmodule Plenario2.ModelRegistry do
  use GenServer

  # Client api 

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def lookup(slug) do
    GenServer.call(__MODULE__, {:lookup, slug})
  end

  def register(meta) do
    GenServer.cast(__MODULE__, {:register, meta})
  end

  # Server callbacks

  def init(args) do
    {:ok, args}
  end

  def handle_call({:lookup, slug}, _sender, state) do
    state = 
      case Map.has_key?(state, slug) do
        true ->
          state
        false ->
          meta = Plenario2.Actions.MetaActions.get(slug, [with_fields: true])
          Map.merge(state, register_meta(meta))
      end

    {:reply, state[slug], state}
  end

  def handle_call(request, sender, state) do
    super(request, sender, state)
  end

  def handle_cast({:register, meta}, state) do
    {:noreply, Map.merge(state, register_meta(meta))}
  end

  def handle_cast(request, state) do
    super(request, state)
  end

  # Server logic 

  defp register_meta(meta) do
    module = "Model." <> meta.slug()
    table = meta.slug()
    fields = 
      Enum.map(meta.data_set_fields(), fn field ->
        {field.name(), field.type()}
      end)
    create_module(module, table, fields)
    %{table => module}
  end

  defp create_module(module, table, fields) do
    Module.create(String.to_atom(module), quote do
      use Plenario2Web, :model
      schema unquote(table) do
        unquote(for {name, type} <- fields do
          quote do
            field unquote(name), unquote(type)
          end
        end)
      end
    end, Macro.Env.location(__ENV__))
  end
end
