defmodule Plenario2Web.TemplateHelpers do

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
end
