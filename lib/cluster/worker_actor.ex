defmodule Cluster.WorkerActor do
  @moduledoc """
  Ator de estado GenServer com isolamento estrito de memória e tolerância a falhas.
  """
  use GenServer, restart: :transient
  require Logger

  # Client API

  def start_link(actor_id, initial_state \\ %{}) do
    GenServer.start_link(__MODULE__, {actor_id, initial_state}, name: via_tuple(actor_id))
  end

  def get_state(actor_id) do
    GenServer.call(via_tuple(actor_id), :get_state)
  end

  def mutate(actor_id, delta) do
    GenServer.call(via_tuple(actor_id), {:mutate, delta})
  end

  def crash(actor_id, reason \\ :simulated_hardware_failure) do
    GenServer.cast(via_tuple(actor_id), {:crash, reason})
  end

  def via_tuple(actor_id) do
    {:via, Registry, {Cluster.ActorRegistry, actor_id}}
  end

  # Server Callbacks

  @impl true
  def init({actor_id, initial_state}) do
    Logger.debug("Iniciando WorkerActor: #{inspect(actor_id)}")
    {:ok, %{id: actor_id, data: initial_state, sequence: 0, updated_at: System.system_time(:millisecond)}}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:mutate, delta}, _from, state) do
    new_data = Map.merge(state.data, delta)
    new_state = %{
      state
      | data: new_data,
        sequence: state.sequence + 1,
        updated_at: System.system_time(:millisecond)
    }
    {:reply, {:ok, new_state.sequence}, new_state}
  end

  @impl true
  def handle_cast({:crash, reason}, _state) do
    Logger.warning("WorkerActor simulando falha catastrófica: #{inspect(reason)}")
    exit(reason)
  end
end
