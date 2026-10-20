defmodule Cluster.ActorSupervisor do
  @moduledoc """
  DynamicSupervisor supervisionando o ciclo de vida de instâncias dinâmicas de WorkerActor.
  Estratégia :one_for_one garante que a falha de um ator não contamine os demais.
  """
  use DynamicSupervisor

  def start_link(init_arg \\ []) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @doc "Inicia um novo WorkerActor sob supervisão."
  def start_actor(actor_id, initial_state \\ %{}) do
    spec = {Cluster.WorkerActor, {actor_id, initial_state}}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  @doc "Termina um ator sob supervisão."
  def stop_actor(actor_id) do
    case Registry.lookup(Cluster.ActorRegistry, actor_id) do
      [{pid, _value}] -> DynamicSupervisor.terminate_child(__MODULE__, pid)
      [] -> {:error, :not_found}
    end
  end

  @doc "Retorna a contagem de atores ativos supervisionados."
  def count_actors do
    DynamicSupervisor.count_children(__MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
