defmodule Cluster.HashRingTest do
  use ExUnit.Case, async: false

  alias Cluster.HashRing

  setup do
    # Garante nós de teste no anel
    HashRing.add_node(:node_alpha, 64)
    HashRing.add_node(:node_beta, 64)
    HashRing.add_node(:node_gamma, 64)

    on_exit(fn ->
      HashRing.remove_node(:node_alpha)
      HashRing.remove_node(:node_beta)
      HashRing.remove_node(:node_gamma)
    end)

    :ok
  end

  test "roteamento determinístico de chaves" do
    {:ok, node1} = HashRing.get_node("user:account:1001")
    {:ok, node2} = HashRing.get_node("user:account:1001")

    assert node1 == node2
    assert node1 in [:node_alpha, :node_beta, :node_gamma, node()]
  end

  test "remoção graciosa de nós redistribui chaves" do
    # Encontra uma chave mapeada para :node_alpha
    key =
      Enum.find(1..500, fn i ->
        case HashRing.get_node("session:#{i}") do
          {:ok, :node_alpha} -> true
          _ -> false
        end
      end)

    if key do
      test_key = "session:#{key}"
      assert {:ok, :node_alpha} = HashRing.get_node(test_key)

      # Remove o nó alpha do anel
      assert :ok = HashRing.remove_node(:node_alpha)

      # A chave deve agora ser roteada para outro nó sem erro
      {:ok, new_target} = HashRing.get_node(test_key)
      assert new_target != :node_alpha
      assert new_target in [:node_beta, :node_gamma, node()]
    end
  end

  test "topologia do anel reflete contagem correta de partições" do
    ring = HashRing.get_ring()
    assert ring.node_count >= 3
    assert ring.vnodes_total >= 192
  end
end
