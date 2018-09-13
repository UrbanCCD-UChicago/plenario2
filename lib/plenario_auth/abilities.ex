defmodule PlenarioAuth.Abilities do
  alias Plenario.Schemas.{
    Chart,
    ChartDataset,
    DataSetField,
    Meta,
    User,
    VirtualDateField,
    VirtualPointField
  }

  alias Plenario.Actions.{
    ChartActions,
    MetaActions
  }

  defimpl Canada.Can, for: Atom do
    @doc """
    Anonymous users can view information about charts, metas and users. All other actions
    on resources are forbidden.
    """
    def can?(nil, action, %Chart{}) when action in [:index, :show], do: true
    def can?(nil, action, %ChartDataset{}) when action in [:index, :show], do: true
    def can?(nil, action, %Meta{}) when action in [:index, :show], do: true
    def can?(nil, action, %User{}) when action in [:index, :show], do: true
    def can?(nil, _, _), do: false
  end

  defimpl Canada.Can, for: User do
    @doc """
    Admin users can perform any action.
    """
    def can?(%User{is_admin: true}, _, _), do: true

    @doc """
    Authenticated users have full access to resources they own and read only access to
    resources they do not (similar to anons).
    """
    def can?(%User{}, action, Meta) when action in [:new, :create], do: true
    def can?(%User{}, action, %Meta{}) when action in [:index, :show], do: true
    def can?(%User{id: user_id}, _, %Meta{user_id: user_id}), do: true
    def can?(%User{}, _, %Meta{}), do: false

    def can?(%User{}, action, DataSetField) when action in [:new, :create], do: true
    def can?(%User{}, action, %DataSetField{}) when action in [:index, :show], do: true

    def can?(%User{id: user_id}, _, %DataSetField{meta_id: meta_id}),
      do: owns_parent?(user_id, meta_id)

    def can?(%User{}, action, VirtualDateField) when action in [:new, :create], do: true
    def can?(%User{}, action, %VirtualDateField{}) when action in [:index, :show], do: true

    def can?(%User{id: user_id}, _, %VirtualDateField{meta_id: meta_id}),
      do: owns_parent?(user_id, meta_id)

    def can?(%User{}, action, VirtualPointField) when action in [:new, :create], do: true
    def can?(%User{}, action, %VirtualPointField{}) when action in [:index, :show], do: true

    def can?(%User{id: user_id}, _, %VirtualPointField{meta_id: meta_id}),
      do: owns_parent?(user_id, meta_id)

    def can?(%User{}, action, Chart) when action in [:new, :create], do: true
    def can?(%User{}, action, %Chart{}) when action in [:index, :show], do: true
    def can?(%User{id: user_id}, _, %Chart{meta_id: meta_id}), do: owns_parent?(user_id, meta_id)

    def can?(%User{}, action, ChartDataset) when action in [:new, :create], do: true
    def can?(%User{}, action, %ChartDataset{}) when action in [:index, :show], do: true

    def can?(%User{id: user_id}, _, %ChartDataset{chart_id: chart_id}) do
      chart = ChartActions.get(chart_id)
      owns_parent?(user_id, chart.meta_id)
    end

    defp owns_parent?(user_id, meta_id) do
      meta = MetaActions.get(meta_id)
      meta.user_id == user_id
    end
  end
end
