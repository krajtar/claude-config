---
name: k8s-force-cleanup
description: Force cleanup stuck Kubernetes resources — terminating namespaces, finalizer-blocked objects, orphaned CRDs/CRs. Use when namespaces are stuck in Terminating state or resources won't delete.
allowed-tools: Bash
argument-hint: [namespace-pattern or resource-type]
---

Force cleanup stuck Kubernetes resources. The user may specify a namespace pattern, resource type, or ask for general cleanup.

## Steps

1. **Identify stuck resources**: Check for namespaces in `Terminating` state and resources with stuck finalizers.

   ```bash
   kubectl get ns --field-selector status.phase=Terminating
   ```

2. **For each stuck namespace** (or the ones matching $ARGUMENTS if provided):

   a. First, list ALL resources in the namespace (not just `kubectl get all`, which misses CRDs, ConfigMaps, etc.):
   ```bash
   kubectl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl get --show-kind --ignore-not-found -n <ns>
   ```

   b. Delete managed resources that commonly hold finalizers:
   ```bash
   # Delete Crossplane Objects (common blocker)
   kubectl delete objects.kubernetes.m.crossplane.io -n <ns> --all --force --grace-period=0 2>/dev/null
   # Delete other custom resources found in step (a)
   ```

   c. Remove finalizers from any resources still stuck in the namespace:
   ```bash
   kubectl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl get --show-kind --ignore-not-found -n <ns> -o json 2>/dev/null | python3 -c "
   import sys, json
   for line in sys.stdin:
       try:
           data = json.loads(line)
           for item in data.get('items', []):
               if item.get('metadata', {}).get('finalizers'):
                   kind = item['kind'].lower()
                   name = item['metadata']['name']
                   api = item.get('apiVersion', '')
                   print(f'Removing finalizers from {kind}/{name} ({api})')
       except: pass
   "
   ```

   c. Force-remove the namespace finalizer to unstick it:
   ```bash
   kubectl get ns <ns> -o json | python3 -c "
   import sys, json
   d = json.load(sys.stdin)
   d['spec']['finalizers'] = []
   print(json.dumps(d))
   " | kubectl replace --raw "/api/v1/namespaces/<ns>/finalize" -f -
   ```

3. **For cluster-scoped resources** (if specified): Remove finalizers and force-delete:
   ```bash
   kubectl patch <resource-type> <name> -p '{"metadata":{"finalizers":[]}}' --type=merge
   kubectl delete <resource-type> <name> --force --grace-period=0
   ```

4. **Verify cleanup**: Confirm the resources are gone.

## Important Notes

- Always list what will be deleted and confirm with the user before proceeding
- Check for ClusterProviderConfigs, ClusterRoleBindings, and other cluster-scoped resources that may have been created by tests
- Chainsaw test namespaces follow the pattern `chainsaw-*`
- Common stuck finalizers: `kubernetes` (namespace), `finalizer.managedresource.crossplane.io` (Crossplane MRs)
