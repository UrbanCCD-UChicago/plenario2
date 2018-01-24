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

  @doc """
  Entrypoint for the registry. `args` is used to set the initial state of a
  registry server and is meant to be a map. An empty map is used by default
  but a prepopulated map can be provided to preload the server.

  Note that by default, this function names the spawned server `__MODULE__1
  under the assumption that only one registry is in use. This is for usability
  purposes so that clients do not need to explicitly specify the registry name.

  ## Examples

      iex> alias Plenario2.ModelRegistry
      iex> {status, _pid} = ModelRegistry.start_link(%{}, :test)
      iex> status == :ok
      true

      iex> alias Plenario2.ModelRegistry
      iex> {status, _pid} = ModelRegistry.start_link(%{
      ...>   1 => :"Model.ExistingModel",
      ...>   "slug" => :"Model.ExistingModel"
      ...> }, :test)
      iex> status == :ok
      true

  """
  def start_link(args, name \\ __MODULE__) do
    GenServer.start_link(__MODULE__, args, name: name)
  end

  @doc """
  Called by `start_link`, this function is used to set the intial state of the
  server.
  """
  def init(args) do
    {:ok, args}
  end

  @doc """
  Asks the registry to return an atom that identifies an ecto schema that
  corresponds to an instance of `Meta`. A module is created on the fly for 
  the first time a schema is requested.

  The returned value can be used to compose queries with Ecto's query api.

  ## Examples

      iex> alias Plenario2.ModelRegistry
      iex> alias Plenario2.Actions.MetaActions
      iex> alias Plenario2Auth.UserActions
      iex> {:ok, user} = UserActions.create("test", "password", "test@email.com")
      iex> {:ok, meta} = MetaActions.create("SomeData", user.id(), "source")
      iex> ModelRegistry.lookup(meta.id())
      :"Model.somedata"

      iex> alias Plenario2.ModelRegistry
      iex> alias Plenario2.Actions.MetaActions
      iex> alias Plenario2Auth.UserActions
      iex> {:ok, user} = UserActions.create("test", "password", "test@email.com")
      iex> {:ok, meta} = MetaActions.create("otherdata", user.id(), "source")
      iex> ModelRegistry.lookup(meta.slug())
      :"Model.otherdata"

  """
  def lookup(slug, pid \\ __MODULE__) do
    GenServer.call(pid, {:lookup, slug})
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
