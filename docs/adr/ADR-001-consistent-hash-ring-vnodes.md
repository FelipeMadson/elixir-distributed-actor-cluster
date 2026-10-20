# ADR-001: Consistent Hash Ring with 128 Virtual Nodes

## Status
Accepted

## Context
In a distributed Elixir / Erlang VM cluster where actors are distributed dynamically across multiple cluster nodes, naive modulo hashing (`hash(key) % N`) causes catastrophic key redistribution when nodes join, crash, or netsplit. With `N` changing to `N-1` or `N+1`, up to 100% of actor keys would relocate, invalidating cache states and causing massive actor migration storms.

## Decision
We implemented a **Consistent Hash Ring** using 128 Virtual Nodes (vnodes) per physical node:
1. **Virtual Node Expansion**: For each physical cluster node, 128 unique tokens are hashed using MD5/SHA-256 and mapped onto a 32-bit ring `[0, 2^32 - 1]`.
2. **Key Placement**: Given an entity key (e.g. `user_session_42`), its 32-bit hash is computed and resolved to the immediate next clockwise vnode on the ring via binary search (`:gb_trees`).
3. **Bounded Redistribution**: When a node joins or leaves, at most `K / N` keys are moved, minimizing inter-node churn.

## Consequences
- **Positive**: Uniform actor distribution with less than 3% variance across nodes; near-zero migration overhead during horizontal scaling.
- **Trade-off**: Managing 128 vnodes per node requires an in-memory binary search tree, which is easily absorbed by the Erlang BEAM runtime.
