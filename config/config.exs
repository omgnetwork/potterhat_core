use Mix.Config

config :potterhat_core,
  nodes: {:apply, {PotterhatCore.EnvConfigProvider, :get_configs, []}},
  retry_interval_ms: {:system, "POTTERHAT_NODE_RETRY_INTERVAL", 5000, {String, :to_integer}}

import_config "#{Mix.env()}.exs"
