defmodule PlenarioWeb do
  def controller do
    quote do
      use Phoenix.Controller, namespace: PlenarioWeb

      import Plug.Conn
      import PlenarioWeb.Gettext
      alias PlenarioWeb.Router.Helpers, as: Routes
      import Canary.Plugs
      import PlenarioWeb.AdminNavPlug

      def put_error_flashes(conn, %Ecto.Changeset{errors: errors}) do
        conn = put_flash(conn, :error, "Please review and correct errors in the form below.")

        case errors[:base] do
          nil ->
            conn

          {msg, _} ->
            put_flash(conn, :error, msg)
        end
      end

      def put_error_flashes(conn, _), do: conn

      plug :admin_nav?
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/plenario_web/templates",
        namespace: PlenarioWeb

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_flash: 1, get_flash: 2, view_module: 1]

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      import PlenarioWeb.ErrorHelpers
      import PlenarioWeb.Gettext
      alias PlenarioWeb.Router.Helpers, as: Routes

      alias Plenario.DataSet

      def format_refresh_cadence(%DataSet{refresh_rate: rate, refresh_interval: interval})
        when not is_nil(rate) and not is_nil(interval), do: "#{rate} #{interval}"

      def format_refresh_cadence(_), do: ""
    end
  end

  def router do
    quote do
      use Phoenix.Router
      use Plug.ErrorHandler
      use Sentry.Plug
      import Plug.Conn
      import Phoenix.Controller
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import PlenarioWeb.Gettext
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
