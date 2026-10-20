defmodule Cluster.ResilienceTest do
  use ExUnit.Case, async: false

  test "ciclo de vida de ator e mutação de estado" do
    actor_id = "order_actor_#{System.unique_integer([:positive])}"
    assert {:ok, _pid} = Cluster.spawn_actor(actor_id, %{balance: 100})

    state0 = Cluster.get_actor_state(actor_id)
    assert state0.id == actor_id
    assert state0.data.balance == 100
    assert state0.sequence == 0

    assert {:ok, 1} = Cluster.send_mutation(actor_id, %{balance: 250, status: :active})

    state1 = Cluster.get_actor_state(actor_id)
    assert state1.data.balance == 250
    assert state1.data.status == :active
    assert state1.sequence == 1
  end

  test "isolamento estrito de falhas: crash de um ator não afeta outros processos" do
    actor_a = "actor_a_#{System.unique_integer([:positive])}"
    actor_b = "actor_b_#{System.unique_integer([:positive])}"

    assert {:ok, _pid_a} = Cluster.spawn_actor(actor_a, %{value: "A"})
    assert {:ok, _pid_b} = Cluster.spawn_actor(actor_b, %{value: "B"})

    # Provoca colapso forçado em A
    Cluster.crash_actor(actor_a, :simulated_crash)

    # Aguarda propagação na árvore de supervisão
    Process.sleep(50)

    # Ator B deve permanecer completamente operacional e intacto
    state_b = Cluster.get_actor_state(actor_b)
    assert state_b.data.value == "B"
    assert state_b.id == actor_b
  end

  test "relatório de telemetria do cluster" do
    health = Cluster.health()
    assert health.status == :healthy
    assert is_map(health.ring)
    assert is_map(health.nodes)
    assert is_map(health.actors)
  end
end
