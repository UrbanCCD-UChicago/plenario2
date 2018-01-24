defmodule Plenario2.ModelRegistry do
  use GenServer
  alias Plenario2.Actions.MetaActions

  @type_map %{
    "boolean" => :boolean,
    "float" => :float,
    "integer" => :integer,
    "text" => :string,
    "timestamptz" => :naive_datetime
  }

  # Client api 

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def lookup(slug) do
    GenServer.call(__MODULE__, {:lookup, slug})
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
          meta = MetaActions.get(slug, [with_fields: true])
          Map.merge(state, register(meta))
      end

    {:reply, Map.fetch!(state, slug), state}
  end

  def handle_call(request, sender, state) do
    super(request, sender, state)
  end

  # Server logic 

  defp register(meta) do
    module = "Model." <> Slug.slugify(meta.name())
    table = Slug.slugify(meta.name())
    fields = 
      Enum.map(meta.data_set_fields(), fn field ->
        {String.to_atom(field.name()), Map.fetch!(@type_map, field.type())}
      end)
    create_module(module, table, fields)

    %{
      meta.id() => String.to_atom(module),
      meta.slug() => String.to_atom(module)
    }
  end

  defp create_module(module, table, fields) do
    Module.create(String.to_atom(module), quote do
      use Ecto.Schema
      @primary_key false
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
