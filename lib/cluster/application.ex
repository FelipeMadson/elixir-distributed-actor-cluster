defmodule Cluster.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: Cluster.ActorRegistry},
      Cluster.HashRing,
      Cluster.ActorSupervisor,
      Cluster.NodeMonitor
    ]

    opts = [strategy: :one_for_one, name: Cluster.TopSupervisor]
    Supervisor.start_link(children, opts)
  end
end
