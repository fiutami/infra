# ADR-001: Docker Compose over Kubernetes

## Status
Accepted

## Context
We need to choose a container orchestration solution for the Fiutami platform.

## Decision
Use Docker Compose for initial deployment, with Kubernetes as future option.

## Rationale
- Simpler setup for small team
- Lower operational overhead
- VPS deployment friendly
- Can migrate to K8s when scale requires it

## Consequences
- Manual scaling required
- No built-in service mesh
- Simpler debugging and troubleshooting
