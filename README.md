# Elixir / OTP 27 Distributed Actor Mesh & Partition-Tolerant Cluster

[![CI](https://github.com/FelipeMadson/elixir-distributed-actor-cluster/actions/workflows/ci.yml/badge.svg)](https://github.com/FelipeMadson/elixir-distributed-actor-cluster/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Elixir](https://img.shields.io/badge/Elixir-1.17+-4B275F.svg)](https://elixir-lang.org/)
[![Erlang/OTP](https://img.shields.io/badge/Erlang%2FOTP-27-A90533.svg)](https://www.erlang.org/)
[![Bilingual: English & Portuguese](https://img.shields.io/badge/Language-EN%20%7C%20PT--BR-blue.svg)](README.pt-BR.md)

Fault-tolerant, high-concurrency **Distributed Actor Mesh** and dynamic supervision cluster engineered in **Elixir 1.17+** and **Erlang/OTP 27**. Implements a deterministic **Consistent Hash Ring** with 128 virtual nodes per physical host, zero single-point-of-failure (*Zero SPOF*), self-healing dynamic supervision trees (`DynamicSupervisor`), and split-brain partition detection.

Authored by **Felipe Madison** ([@FelipeMadson](https://github.com/FelipeMadson)).

[Versão em Português](README.pt-BR.md) · [Portfolio](https://felipemadson.github.io/portfolio/) · [Engineering Handbook Vol 10](https://github.com/FelipeMadson/software-engineering-handbook)

---

## Architectural Topology

```
                         ┌──────────────────────────────────────────────┐
                         │              TOP-LEVEL SUPERVISOR            │
                         │             (Cluster.TopSupervisor)          │
                         └──────┬──────────────┬──────────────┬─────────┘
                                │              │              │
             ┌──────────────────┴──┐    ┌──────┴──────┐    ┌──┴──────────────────┐
             ▼                     ▼    ▼             ▼    ▼                     ▼
     ┌───────────────┐     ┌───────────────┐     ┌───────────────┐     ┌───────────────┐
     │ ActorRegistry │     │   HashRing    │     │ActorSupervisor│     │  NodeMonitor  │
     │(Unique Keys)  │     │(SHA-256 Ring) │     │(:one_for_one) │     │(:net_kernel)  │
     └───────────────┘     └───────┬───────┘     └───────┬───────┘     └───────────────┘
                                   │                     │
                                   │ Routes to Actor     │ Supervises Lifecycles
                                   ▼                     ▼
                         ┌──────────────────────────────────────────────┐
                         │           EPHEMERAL WORKER ACTORS            │
                         │   WorkerActor 1  │ WorkerActor 2 │  ...      │
                         │   State Isolated │ Let-It-Crash  │ Mailbox   │
                         └──────────────────────────────────────────────┘
```

---

## Key Capabilities

- **Consistent Hash Ring (Virtual Nodes)**: 128 virtual nodes per node over a $2^{32}-1$ integer ring with SHA-256 key hashing for balanced distribution and deterministic routing.
- **Hierarchical OTP Supervision**: `DynamicSupervisor` with `:one_for_one` strategy guarantees that individual actor process failures never cascade into global outages (*Let it Crash*).
- **Process Registry & Sharding**: Distributed `:via` tuples registered in `Cluster.ActorRegistry` for location-transparent message dispatch.
- **Node Discovery & Split-Brain Monitoring**: `Cluster.NodeMonitor` detects `:nodeup` and `:nodedown` signals from Erlang's distributed runtime kernel, automatically re-balancing the ring.
- **Stateful GenServer Isolation**: Independent heap and garbage collection per actor process, delivering microsecond message passing and zero shared-memory locks.

---

## Quickstart

### Prerequisites
- [Elixir 1.17+](https://elixir-lang.org/install.html)
- [Erlang/OTP 27](https://www.erlang.org/downloads)

### Setup & Compilation
```bash
mix deps.get
mix compile
```

### Run Test Suite
```bash
mix test
```

### Interactive Cluster Shell
```bash
iex -S mix
```

```elixir
# Spawn a stateful actor
{:ok, _pid} = Cluster.spawn_actor("order_123", %{total: 100})

# Mutate state
{:ok, 1} = Cluster.send_mutation("order_123", %{status: :paid})

# Inspect state
Cluster.get_actor_state("order_123")

# Inspect cluster health
Cluster.health()
```

---

## License

This project is licensed under the [MIT License](LICENSE).  
Authored by **Felipe Madison** ([@FelipeMadson](https://github.com/FelipeMadson)).
