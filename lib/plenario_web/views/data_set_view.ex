defmodule PlenarioWeb.DataSetView do
  use PlenarioWeb, :view

  import Plenario.DataSet, only: [
    refresh_interval_choices: 0,
    src_type_choices: 0
  ]
end
