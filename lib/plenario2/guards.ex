defmodule Plenario2.Guards do
  @moduledoc """
  Defines custom guards to be used in action functions.
  """

  @doc """
  Determins if a given value is a String or an Integer.
  ## Example
    defmodule Actions do
      import Plenario2.Actions.Guards, only: [is_id: 1]
      def list_for_meta(meta) when not is_id(value) do
        list_for_meta(meta.id)
      end
      def list_for_meta(meta_id) when is_id(meta_id) do
        :action_logic
      end
    end
  """
  defmacro is_id(value) do
    quote do
      is_bitstring(unquote(value)) or is_integer(unquote(value))
    end
  end
end
