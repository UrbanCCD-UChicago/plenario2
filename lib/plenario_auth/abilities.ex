defmodule PlenarioAuth.Abilities do
  @moduledoc """
  Defines authorization abilities for users in relation to resources. For
  example, we only want the user who owns a meta to be able to edit it.
  """

  alias Plenario.Schemas.{
    User,
    Meta,
    DataSetField,
    VirtualDateField,
    VirtualPointField,
    Chart,
    ChartDataset
  }

  alias Plenario.Actions.{
    MetaActions,
    ChartActions
  }

  defimpl Canada.Can, for: Atom do

    @doc """
    Anonymous users can only access the :index and :show actions of
    Metas, Users, Charts and ChartDatasets.
    """
    def can?(nil, action, %Meta{}) when action in [:index, :show], do: true
    def can?(nil, action, %User{}) when action in [:index, :show], do: true
    def can?(nil, action, %ChartDataset{}) when action in [:show, :list], do: true
    def can?(nil, action, %Chart{}) when action in [:show, :list, :render_chart], do: true
    def can?(nil, _, _), do: false
  end

  defimpl Canada.Can, for: User do

    @doc """
    Admin users can perform any action, regardless of who owns the resource.
    """
    def can?(%User{is_admin: true}, _, _), do: true

    @doc """
    Authenticated users can only access the Meta index and show, unless they
    are the owner of the Meta.
    """
    def can?(%User{id: user_id}, _, %Meta{user_id: user_id}), do: true
    def can?(%User{}, action, Meta) when action in [:new, :create], do: true
    def can?(%User{}, action, %Meta{}) when action in [:show], do: true
    def can?(%User{}, _, %Meta{}), do: false

    @doc """
    Authenticated users who own the DataSetField's parent Meta are the only
    users able to access it.
    """
    def can?(%User{id: user_id}, _, %DataSetField{meta_id: meta_id}) do
      meta = MetaActions.get(meta_id)
      meta.user_id == user_id
    end

    @doc """
    Authenticated users who own the VirtualDateField's parent Meta are the only
    users able to access it.
    """
    def can?(%User{}, action, VirtualDateField) when action in [:new, :create], do: true
    def can?(%User{id: user_id}, _, %VirtualDateField{meta_id: meta_id}) do
      meta = MetaActions.get(meta_id)
      meta.user_id == user_id
    end

    @doc """
    Authenticated users who own the VirtualPointField's parent Meta are the only
    users able to access it.
    """
    def can?(%User{}, action, VirtualPointField) when action in [:new, :create], do: true
    def can?(%User{id: user_id}, _, %VirtualPointField{meta_id: meta_id}) do
      meta = MetaActions.get(meta_id)
      meta.user_id == user_id
    end

    @doc """
    Authenticated users who own the Chart's parent Meta are the only users
    able to access its write/destroy actions.
    """
    def can?(%User{}, action, Chart) when action in [:new, :create], do: true
    def can?(%User{id: user_id}, _, %Chart{meta_id: meta_id}) do
      meta = MetaActions.get(meta_id)
      meta.user_id == user_id
    end

    @doc """
    Authenticated users who own the ChartDataset's parent Chart's parent Meta
    are the only users able to access its write/destroy actions.
    """
    def can?(%User{}, action, ChartDataset) when action in [:new, :create], do: true
    def can?(%User{id: user_id}, _, %ChartDataset{chart_id: chart_id}) do
      chart = ChartActions.get(chart_id)
      meta = MetaActions.get(chart.meta_id)
      meta.user_id == user_id
    end
  end
end
