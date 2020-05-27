defmodule Clayton.Repo do
  use Ecto.Repo,
    otp_app: :clayton,
    adapter: Ecto.Adapters.Postgres
end
