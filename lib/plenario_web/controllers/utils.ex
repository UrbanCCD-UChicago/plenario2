defmodule PlenarioWeb.Controllers.Utils do

  def parse_date_string(date_string) do
    ndt =
      case Timex.parse(date_string, "{YYYY}-{M}-{D}") do
        {:ok, result} ->
          result

        {:error, _} ->
          case Timex.parse(date_string, "{M}/{D}/{YYYY}") do
            {:ok, result} ->
              result

            {:error, _} ->
              case Timex.parse(date_string, "{D}/{M}/{YYYY}") do
                {:ok, result} ->
                  result

                {:error, _} ->
                  Timex.today()
              end
          end
      end

    Timex.format!(ndt, "{YYYY}-{0M}-{0D}")
  end
end
