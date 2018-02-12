defmodule PlenarioWeb.Web.ControllerUtils do
  import Phoenix.Controller, only: [put_flash: 3]

  def flash_base_errors(conn, %Ecto.Changeset{errors: errors}) do
    {message, _} = Keyword.get(errors, :base, {nil, []})

    conn =
      case message do
        nil -> conn
        _ -> put_flash(conn, :error, message)
      end

    conn
  end
end
