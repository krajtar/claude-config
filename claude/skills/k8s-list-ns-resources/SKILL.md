---
name: k8s-list-ns-resources
description: List ALL resources in a Kubernetes namespace — including CRDs, ConfigMaps, Secrets, and other resources that `kubectl get all` misses. Useful for debugging stuck Terminating namespaces or auditing namespace contents.
allowed-tools: Bash
argument-hint: <namespace>
---

List every resource in a given Kubernetes namespace. Unlike `kubectl get all`, this discovers all API resource types and queries each one, so nothing is missed.

## Steps

1. **List all namespaced resources** in the namespace provided via `$ARGUMENTS`:

   ```bash
   kubectl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl get --show-kind --ignore-not-found -n <namespace>
   ```

2. **Summarize findings**: Report what resource types and counts were found. Highlight any resources with finalizers or in a deleting/terminating state, as these are likely blockers for namespace deletion.

3. **If the namespace is stuck in Terminating**: Suggest using `/k8s-force-cleanup <namespace>` to remove stuck resources and finalizers.

## Important Notes

- This is a read-only, non-destructive operation — it only lists resources
- **This is a long-running, expensive command** — it queries every namespaced API resource type, so it may take 30+ seconds on clusters with many CRDs. Only use it when you don't know the exact resource type you're looking for. If you already know the type (e.g., `crossplanes.app.europeanweather.cloud`), query it directly with `kubectl get <type>` instead
- Pay attention to Crossplane managed resources (`objects.kubernetes.m.crossplane.io`, XRs, MRs) as these commonly hold finalizers
