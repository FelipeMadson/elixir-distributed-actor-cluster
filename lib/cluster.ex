defmodule Cluster do
  @moduledoc """
  Fachada pública da malha de atores distribuídos e tolerância a falhas em Elixir / OTP 27.
  """

  @doc "Cria um novo ator supervisionado no cluster."
  def spawn_actor(actor_id, initial_state \\ %{}) do
    case Cluster.ActorSupervisor.start_actor(actor_id, initial_state) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
      other -> other
    end
  end

  @doc "Envia mutação de estado determinística para o ator especificado."
  def send_mutation(actor_id, delta) do
    Cluster.WorkerActor.mutate(actor_id, delta)
  end

  @doc "Consulta o estado instantâneo de um ator."
  def get_actor_state(actor_id) do
    Cluster.WorkerActor.get_state(actor_id)
  end

  @doc "Calcula qual nó físico do cluster é o guardião responsável pela chave."
  def route_key(key) do
    Cluster.HashRing.get_node(key)
  end

  @doc "Simula colapso de processo de um ator para teste de auto-recuperação (Let It Crash)."
  def crash_actor(actor_id, reason \\ :simulated_fault) do
    Cluster.WorkerActor.crash(actor_id, reason)
  end

  @doc "Retorna a telemetria do cluster e resumo de supervisão de atores."
  def health do
    %{
      ring: Cluster.HashRing.get_ring(),
      nodes: Cluster.NodeMonitor.status(),
      actors: Cluster.ActorSupervisor.count_actors(),
      status: :healthy,
      author: "Felipe Madison (@FelipeMadson)",
      version: "1.0.0"
    }
  end
end
