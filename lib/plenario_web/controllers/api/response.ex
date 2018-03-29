defmodule PlenarioWeb.Api.Response.Meta.Links do
  @type t :: %__MODULE__{
    current: binary(),
    previous: binary(),
    next: binary()
  }

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

  @enforce_keys [:meta, :error]
  defstruct @enforce_keys
end
