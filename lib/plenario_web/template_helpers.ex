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
end
