defmodule PlenarioWeb.Api.Response.Meta.Links do
  @type t :: %__MODULE__{
    current: binary(),
    previous: binary(),
    next: binary()
  }

  @derive [Poison.Encoder]
  defstruct [
    current: "",
    previous: "",
    next: ""
  ]
end


defmodule PlenarioWeb.Api.Response.Meta.Params do
  @type t :: %__MODULE__{
    page_size: integer()
  }

  @derive [Poison.Encoder]
  defstruct [
    page_size: 500
  ]
end


defmodule PlenarioWeb.Api.Response.Meta.Counts do
  @type t :: %__MODULE__{
    pages: integer(),
    total_records: integer(),
    data: integer(),
    errors: integer()
  }

  @derive [Poison.Encoder]
  defstruct [
    pages: 0,
    total_records: 0,
    data: 0,
    errors: 0
  ]
end


defmodule PlenarioWeb.Api.Response.Meta do
  @type t :: %__MODULE__{
    links: Links.t(),
    params: Params.t(),
    counts: Counts.t()
  }

  @derive [Poison.Encoder]
  defstruct [
    links: %PlenarioWeb.Api.Response.Meta.Links{},
    params: %PlenarioWeb.Api.Response.Meta.Params{},
    counts: %PlenarioWeb.Api.Response.Meta.Counts{}
  ]
end


defmodule PlenarioWeb.Api.Response do
  @type t :: %__MODULE__{
    meta: Meta.t(),
    data: list(map)
  }

  @derive [Poison.Encoder]
  defstruct [
    meta: %PlenarioWeb.Api.Response.Meta{},
    data: []
  ]
end


defmodule PlenarioWeb.Api.ErrorResponse do
  @type t :: %__MODULE__{
    meta: Meta.t(),
    error: Error.t()
  }

  @derive [Poison.Encoder]
  defstruct [
    meta: %PlenarioWeb.Api.Response.Meta{},
    error: []
  ]
end
