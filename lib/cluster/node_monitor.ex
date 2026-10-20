defmodule Cluster.NodeMonitor do
  @moduledoc """
  GenServer de monitoramento de saúde do cluster.
  Recebe eventos de :nodeup e :nodedown da VM Erlang e atualiza o anel de hash automaticamente.
  """
  use GenServer
  require Logger

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Retorna a lista de nós ativos monitorados e status de partição."
  def status do
    GenServer.call(__MODULE__, :status)
  end

  @impl true
  def init(_opts) do
    :net_kernel.monitor_nodes(true)
    Logger.info("NodeMonitor iniciado no nó: #{inspect(node())}")
    {:ok, %{local_node: node(), remote_nodes: Node.list(), partition_detected: false}}
  end

  @impl true
  def handle_info({:nodeup, node_name}, state) do
    Logger.info("Novo nó ingressou no cluster: #{inspect(node_name)}")
    Cluster.HashRing.add_node(node_name)
    {:noreply, %{state | remote_nodes: Node.list(), partition_detected: false}}
  end

  @impl true
  def handle_info({:nodedown, node_name}, state) do
    Logger.warning("Nó desconectado do cluster: #{inspect(node_name)}")
    Cluster.HashRing.remove_node(node_name)
    {:noreply, %{state | remote_nodes: Node.list(), partition_detected: true}}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, state, state}
  end
end
