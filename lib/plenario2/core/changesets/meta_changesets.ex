defmodule Plenario2.Core.Changesets.MetaChangeset do
  import Ecto.Changeset
  alias Plenario2.Core.Tokens

  def create(struct, params) do
    struct
    |> cast(params, [
         :name,
         :user_id,
         :description,
         :attribution,
         :source_url,
         :source_type,
         :refresh_rate,
         :refresh_interval,
         :refresh_starts_on,
         :refresh_ends_on,
         :srid,
         :timezone
       ])
    |> validate_required([:name, :user_id, :source_url, :source_type])
    |> cast_assoc(:user)
    |> unique_constraint(:name)
    |> _set_slug()
    |> _validate_refresh_rate()
    |> _validate_refresh_interval()
    |> _validate_refresh_ends_on()
    |> _validate_source_type()
  end

  ##
  # operations

  defp _set_slug(changeset), do: changeset |> put_change(:slug, Tokens.generate_token())

  ##
  # validations

  defp _validate_refresh_rate(changeset) do
    rr = get_field(changeset, :refresh_rate)

    if Enum.member?([nil, "hours", "days", "weeks", "months", "years"], rr) do
      changeset
    else
      changeset |> add_error(:refresh_rate, "Invalid value `#{rr}`")
    end
  end

  defp _validate_refresh_interval(changeset) do
    rr = get_field(changeset, :refresh_rate)

    if rr == nil do
      changeset |> put_change(:refresh_interval, nil)
    else
      ri = get_field(changeset, :refresh_interval)

      if is_integer(ri) and ri > 0 do
        changeset
      else
        changeset |> add_error(:refresh_interval, "Invalid value `#{ri}`")
      end
    end
  end

  defp _validate_refresh_ends_on(changeset) do
    rso = get_field(changeset, :refresh_starts_on)

    if rso == nil do
      changeset |> put_change(:refresh_ends_on, nil)
    else
      reo = get_field(changeset, :refresh_ends_on)

      if reo > rso do
        changeset
      else
        changeset |> add_error(:refresh_ends_on, "Invalid: end date cannot precede start date")
      end
    end
  end

  defp _validate_source_type(changeset) do
    st = get_field(changeset, :source_type)

    if Enum.member?(["csv", "tsv", "shp", "json"], st) do
      changeset
    else
      changeset |> add_error(:source_type, "Invalid type `#{st}`")
    end
  end
end
