defmodule Plenario2.Changesets.MetaChangesets do
  import Ecto.Changeset
  alias Plenario2.Tokens

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
    |> unique_constraint(:source_url)
    |> _set_slug()
    |> _validate_refresh_rate()
    |> _validate_refresh_interval()
    |> _validate_refresh_ends_on()
    |> _validate_source_type()
    |> put_change(:state, "new")
  end

  def update_name(meta, params) do
    meta
    |> cast(params, [:name])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end

  def update_user(meta, params) do
    meta
    |> cast(params, [:user_id])
    |> validate_required([:user_id])
    |> cast_assoc(:user)
  end

  def update_source_info(meta, params) do
    meta
    |> cast(params, [:source_url, :source_type])
    |> unique_constraint(:source_url)
    |> _validate_source_type()
  end

  def update_description_info(meta, params) do
    meta
    |> cast(params, [:description, :attribution])
  end

  def update_refresh_info(meta, params) do
    meta
    |> cast(params, [:refresh_rate, :refresh_interval, :refresh_starts_on, :refresh_ends_on])
    |> _validate_refresh_rate()
    |> _validate_refresh_interval()
    |> _validate_refresh_ends_on()
  end

#  def update_bbox(meta, params) do
#    meta
#    |> cast(params, [:bbox])
#  end

#  def update_timerange(meta, params) do
#    meta
#    |> cast(params, [:timerange])
#  end

  def update_next_refresh(meta, params) do
    meta
    |> cast(params, [:next_refresh])
  end

  ##
  # operations

  defp _set_slug(changeset), do: changeset |> put_change(:slug, Tokens.generate_token())

  ##
  # validations

  defp _validate_refresh_rate(changeset) do
    rr = get_field(changeset, :refresh_rate)

    if Enum.member?([nil, "minutes", "hours", "days", "weeks", "months", "years"], rr) do
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
      changeset
    end
  end

  defp _validate_refresh_ends_on(changeset) do
    rso = get_field(changeset, :refresh_starts_on)

    if rso == nil do
      changeset |> put_change(:refresh_ends_on, nil)
    else
      reo = get_field(changeset, :refresh_ends_on)

      if reo > rso or reo == nil do
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
