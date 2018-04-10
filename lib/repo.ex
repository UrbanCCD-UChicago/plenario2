defmodule Plenario.Repo do
  use Ecto.Repo, otp_app: :plenario
  use Scrivener, page_size: 500
end
