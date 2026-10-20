defmodule Cluster.HashRing do
  @moduledoc """
  Implementação funcional e determinística de Consistent Hash Ring com nós virtuais (VNodes).
  Distribui chaves de atores uniformemente entre os nós participantes do cluster.
  """
  use GenServer

  @default_vnodes 128
  @ring_space 4_294_967_296 # 2^32

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Adiciona um nó físico ao anel com réplicas virtuais."
  def add_node(node_name, vnodes \\ @default_vnodes) do
    GenServer.call(__MODULE__, {:add_node, node_name, vnodes})
  end

  @doc "Remove um nó físico do anel."
  def remove_node(node_name) do
    GenServer.call(__MODULE__, {:remove_node, node_name})
  end

  @doc "Determina qual nó físico é responsável por uma determinada chave."
  def get_node(key) do
    GenServer.call(__MODULE__, {:get_node, key})
  end

  @doc "Retorna a topologia atual do anel com contagem de nós e partições."
  def get_ring do
    GenServer.call(__MODULE__, :get_ring)
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    # Inicializa o nó local como primeiro membro do anel
    state = add_node_to_state(%{nodes: MapSet.new(), ring: []}, node(), @default_vnodes)
    {:ok, state}
  end

  @impl true
  def handle_call({:add_node, node_name, vnodes}, _from, state) do
    new_state = add_node_to_state(state, node_name, vnodes)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:remove_node, node_name}, _from, state) do
    if MapSet.member?(state.nodes, node_name) do
      new_nodes = MapSet.delete(state.nodes, node_name)
      new_ring = Enum.reject(state.ring, fn {_hash, n} -> n == node_name end)
      {:reply, :ok, %{state | nodes: new_nodes, ring: new_ring}}
    else
      {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call({:get_node, key}, _from, %{ring: []} = state) do
    {:reply, {:error, :empty_ring}, state}
  end

  @impl true
  def handle_call({:get_node, key}, _from, state) do
    hash = hash_key(to_string(key))
    # Busca o primeiro nó cujo hash seja maior ou igual ao hash da chave (ou dá a volta para o primeiro nó)
    target_node =
      case Enum.find(state.ring, fn {ring_hash, _node} -> ring_hash >= hash end) do
        {_ring_hash, node_name} -> node_name
        nil ->
          # Circunda o anel até o início
          {_ring_hash, first_node} = hd(state.ring)
          first_node
      end

    {:reply, {:ok, target_node}, state}
  end

  @impl true
  def handle_call(:get_ring, _from, state) do
    summary = %{
      node_count: MapSet.size(state.nodes),
      nodes: MapSet.to_list(state.nodes),
      vnodes_total: length(state.ring)
    }
    {:reply, summary, state}
  end

  # Funções Auxiliares

  defp add_node_to_state(state, node_name, vnodes) do
    vnode_entries =
      for i <- 0..(vnodes - 1) do
        hash = hash_key("#{node_name}:vnode_#{i}")
        {hash, node_name}
      end

    new_ring = (state.ring ++ vnode_entries) |> Enum.sort_by(fn {hash, _} -> hash end)
    new_nodes = MapSet.put(state.nodes, node_name)
    %{state | nodes: new_nodes, ring: new_ring}
  end

  defp hash_key(key) when is_binary(key) do
    <<hash_int::32, _rest::binary>> = :crypto.hash(:sha256, key)
    rem(hash_int, @ring_space)
  end
end
