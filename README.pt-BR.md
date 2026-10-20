# Malha de Atores Distribuídos e Cluster Tolerante a Partições em Elixir / OTP 27

[![CI](https://github.com/FelipeMadson/elixir-distributed-actor-cluster/actions/workflows/ci.yml/badge.svg)](https://github.com/FelipeMadson/elixir-distributed-actor-cluster/actions)
[![Licença: MIT](https://img.shields.io/badge/Licen%C3%A7a-MIT-yellow.svg)](LICENSE)
[![Elixir](https://img.shields.io/badge/Elixir-1.17+-4B275F.svg)](https://elixir-lang.org/)
[![Erlang/OTP](https://img.shields.io/badge/Erlang%2FOTP-27-A90533.svg)](https://www.erlang.org/)
[![Bilingue: Inglês & Português](https://img.shields.io/badge/Idioma-EN%20%7C%20PT--BR-blue.svg)](README.md)

Malha de atores distribuídos de alta concorrência e cluster tolerante a falhas desenvolvido em **Elixir 1.17+** e **Erlang/OTP 27**. Implementa um **Consistent Hash Ring** determinístico com 128 nós virtuais por host físico, arquitetura sem ponto único de falha (*Zero SPOF*), árvores dinâmicas de auto-cura (`DynamicSupervisor`) e monitoramento ativo de partições de rede (*Split-Brain Detection*).

De autoria de **Felipe Madison** ([@FelipeMadson](https://github.com/FelipeMadson)).

[English Version](README.md) · [Portfólio](https://felipemadson.github.io/portfolio/) · [Manual de Engenharia Vol 10](https://github.com/FelipeMadson/software-engineering-handbook)

---

## Topologia Arquitetural

```
                         ┌──────────────────────────────────────────────┐
                         │            SUPERVISOR DE TOPO (OTP)          │
                         │             (Cluster.TopSupervisor)          │
                         └──────┬──────────────┬──────────────┬─────────┘
                                │              │              │
             ┌──────────────────┴──┐    ┌──────┴──────┐    ┌──┴──────────────────┐
             ▼                     ▼    ▼             ▼    ▼                     ▼
     ┌───────────────┐     ┌───────────────┐     ┌───────────────┐     ┌───────────────┐
     │ ActorRegistry │     │   HashRing    │     │ActorSupervisor│     │  NodeMonitor  │
     │(Chaves Únicas)│     │(Anel SHA-256) │     │(:one_for_one) │     │(:net_kernel)  │
     └───────────────┘     └───────┬───────┘     └───────┬───────┘     └───────────────┘
                                   │                     │
                                   │ Roteia Chave        │ Supervisiona Atores
                                   ▼                     ▼
                         ┌──────────────────────────────────────────────┐
                         │           ATORES WORKER EFÊMEROS             │
                         │   WorkerActor 1  │ WorkerActor 2 │  ...      │
                         │  Memória Isolada │ Let-It-Crash  │ Mailbox   │
                         └──────────────────────────────────────────────┘
```

---

## Principais Recursos

- **Consistent Hash Ring com Nós Virtuais**: 128 VNodes por máquina sobre um anel de $2^{32}-1$ posições com hashing SHA-256, garantindo equilíbrio uniforme e rebalanceamento suave.
- **Supervisão Hierárquica OTP**: Estratégia `:one_for_one` do `DynamicSupervisor` assegura que a falha de um ator não cause interrupção do sistema (*filosofia Let It Crash*).
- **Roteamento Transparente**: Despacho de mensagens desacoplado da localização física através do `Cluster.ActorRegistry` e tuplas `:via`.
- **Detecção de Split-Brain & Topologia**: `Cluster.NodeMonitor` escuta eventos do kernel de rede da VM Erlang (`:nodeup` / `:nodedown`), ajustando o anel automaticamente.
- **Processos GenServer Isolados**: Cada ator opera com heap e garbage collector independentes, sem travas compartilhadas de memória e com latência de mensagens em microssegundos.

---

## Execução Rápida

### Pré-requisitos
- [Elixir 1.17+](https://elixir-lang.org/install.html)
- [Erlang/OTP 27](https://www.erlang.org/downloads)

### Compilação
```bash
mix deps.get
mix compile
```

### Executar Testes
```bash
mix test
```

### Shell Interativo do Cluster
```bash
iex -S mix
```

```elixir
# Inicia um ator supervisionado
{:ok, _pid} = Cluster.spawn_actor("order_123", %{total: 100})

# Envia mutação
{:ok, 1} = Cluster.send_mutation("order_123", %{status: :paid})

# Consulta estado
Cluster.get_actor_state("order_123")

# Relatório de saúde do cluster
Cluster.health()
```

---

## Licença

Este projeto é licenciado sob a [Licença MIT](LICENSE).  
De autoria de **Felipe Madison** ([@FelipeMadson](https://github.com/FelipeMadson)).
