# ADR-002: DynamicSupervisor Self-Healing & Registry Routing

## Status
Accepted

## Context
Individual distributed actor entities (representing shopping carts, IoT devices, or trading sessions) are transient, have independent lifecycles, and can fail independently due to network timeouts or unexpected state anomalies. A crash in one entity must never compromise adjacent actors or the node runtime itself.

## Decision
We adopted **OTP 27 DynamicSupervisor** paired with an Elixir **Registry** partitioned across cluster nodes:
1. **Dynamic Child Lifecycle**: Actors are spawned on-demand via `DynamicSupervisor.start_child/2` with `:transient` restart strategies.
2. **Crash Isolation**: Unhandled exceptions in worker actors terminate only the afflicted GenServer. The supervisor isolates failure without restarting unrelated actors.
3. **Registry-Based Lookup**: Nodes use `{:via, Registry, {Cluster.Registry, key}}` for O(1) process lookup, with automatic cleanup upon actor termination.

## Consequences
- **Positive**: Complies with the Erlang "Let It Crash" philosophy; guaranteed fault isolation and bounded recovery.
- **Trade-off**: Requires explicit state snapshotting (e.g. to durable storage or mnesia) if state recovery after unexpected crashes is required.
