defmodule PlenarioWeb.TemplateHelpers do
  import Phoenix.HTML.Tag

  def s_plural(word, length_) do
    case length_ do
      1 -> word
      _ -> word <> "s"
    end
  end

  def es_plural(word, length_) do
    case length_ do
      1 -> word
      _ -> word <> "es"
    end
  end

  def irregular_plural(singular, plural, length_) do
    case length_ do
      1 -> singular
      _ -> plural
    end
  end

  def psql_to_human(value) do
    Map.get(
      %{
        "text" => "Text",
        "integer" => "Integer",
        "float" => "Decimal",
        "boolean" => "True/False",
        "timestamp" => "Date"
      },
      value
    )
  end

  @doc """
  A helper function that generates a tooltip.
  """
  def tooltip(message) do
    content_tag(:span, "🛈",
      data: [toggle: "tooltip", placement: "top"],
      title: message)
  end

  def make_p(message) do
    split =
      String.split(message, "\n\n")
      |> Enum.join("</p></p>")

    Phoenix.HTML.raw("<p>#{split}</p>")
  end

  def strftime(%NaiveDateTime{} = timestamp) do
    Timex.format!(timestamp, "%d %B %Y %I:%M:%S %p", :strftime)
  end

  def strftime(%Plenario.TsRange{lower: lower, upper: upper}) do
    lower = strftime(lower)
    upper = strftime(upper)
    "#{lower} to #{upper}"
  end
end
