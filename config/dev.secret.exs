# Since configuration is shared in umbrella projects, this file
# should only configure the :clayton application itself
# and only for organization purposes. All other config goes to
# the umbrella root.
use Mix.Config

# Configure your database
config :clayton, Clayton.Repo,
  username: "manfred",
  password: "how.low.max.pool",
  database: "clayton",
  pool_size: 15

