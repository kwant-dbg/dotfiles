---
name: kubectl
description: Kubernetes cluster operations using kubectl. Triggered by requests to check pods, deployments, services, logs, describe resources, apply manifests, or any kubectl-related operations. Handles common k8s debugging and management tasks.
---

# Kubectl Skill

## Purpose
Streamline Kubernetes cluster operations by providing intelligent kubectl command execution with context-aware suggestions and common debugging workflows.

## Trigger Phrases
- "check pods in [namespace]"
- "get deployments" / "show deployments"
- "logs for [pod-name]"
- "describe pod [name]"
- "apply [manifest]"
- "what's wrong with [resource]"
- "scale [deployment] to [N]"
- "restart [deployment]"
- Any request involving kubectl or Kubernetes resources

## Core Capabilities

### 1. Resource Inspection
When asked to check or view resources:

```bash
# Get resources with wide output for more context
kubectl get pods -n <namespace> -o wide
kubectl get deployments -n <namespace> -o wide
kubectl get services -n <namespace> -o wide

# For all namespaces
kubectl get pods --all-namespaces -o wide
```

**Smart defaults:**
- If no namespace specified, check current context namespace
- Show wide output by default for better context
- Highlight pods that are not Running/Ready

### 2. Debugging Workflows

#### Pod Issues
When a pod is not running properly:

TODO(human): Design the debugging workflow sequence

```bash
# Step 1: Get pod status
kubectl get pod <pod-name> -n <namespace> -o wide

# Step 2: Describe to see events
kubectl describe pod <pod-name> -n <namespace>

# Step 3: Check logs (previous if crashed)
kubectl logs <pod-name> -n <namespace> --tail=100

# If pod crashed/restarted
kubectl logs <pod-name> -n <namespace> --previous --tail=100
```

After showing results, analyze:
- **ImagePullBackOff**: Check image name and registry access
- **CrashLoopBackOff**: Check logs and resource limits
- **Pending**: Check node resources and scheduling constraints
- **OOMKilled**: Check memory limits vs actual usage

#### Service Connectivity
When debugging service issues:

```bash
# Check service endpoints
kubectl get endpoints <service-name> -n <namespace>

# Verify service selector matches pods
kubectl get service <service-name> -n <namespace> -o yaml | grep -A5 selector
kubectl get pods -n <namespace> -l <label-from-selector> -o wide
```

### 3. Log Management

**Smart log fetching:**
```bash
# Recent logs with timestamps
kubectl logs <pod-name> -n <namespace> --tail=100 --timestamps

# Follow logs (for active debugging)
kubectl logs <pod-name> -n <namespace> --follow --tail=50

# Multiple containers
kubectl logs <pod-name> -c <container-name> -n <namespace>

# Previous instance (if crashed)
kubectl logs <pod-name> -n <namespace> --previous
```

**When to use each:**
- `--tail=100`: Initial investigation
- `--follow`: Watching for real-time issues
- `--previous`: Crash investigation
- `--timestamps`: Timeline correlation

### 4. Manifest Operations

When applying or modifying resources:

```bash
# Dry-run first (safety check)
kubectl apply -f <manifest> --dry-run=client

# Then apply
kubectl apply -f <manifest>

# Verify the change
kubectl get <resource-type> <resource-name> -n <namespace> -o yaml
```

**Always:**
1. Show what will change (dry-run or diff)
2. **WAIT FOR USER CONFIRMATION** before running `kubectl apply` (never auto-execute)
3. Verify after applying

### 5. Common Operations

**Scaling (requires confirmation):**
```bash
kubectl scale deployment <name> -n <namespace> --replicas=<N>
```
⚠️ Always show current replica count and wait for user confirmation before scaling.

**Restart (requires confirmation):**
```bash
kubectl rollout restart deployment <name> -n <namespace>
kubectl rollout status deployment <name> -n <namespace>
```
⚠️ This will recreate all pods - always confirm with user first.

**Port forwarding (safe, no confirmation needed):**
```bash
kubectl port-forward pod/<pod-name> <local-port>:<pod-port> -n <namespace>
# Or for service
kubectl port-forward service/<service-name> <local-port>:<service-port> -n <namespace>
```
Note: Port forwarding is read-only and doesn't modify the cluster.

**Execute commands in pod (requires confirmation):**
```bash
kubectl exec -it <pod-name> -n <namespace> -- /bin/bash
# Or specific command
kubectl exec <pod-name> -n <namespace> -- <command>
```
⚠️ Confirm with user before executing commands inside pods.

## Context Awareness

### Check Current Context
Always start by understanding the environment:

```bash
# Show current context
kubectl config current-context

# Show current namespace
kubectl config view --minify --output 'jsonpath={..namespace}'
```

### Multi-Cluster Safety
If user has multiple clusters:
1. **Always** confirm which cluster before destructive operations
2. Show current context prominently
3. Suggest setting namespace: `kubectl config set-context --current --namespace=<ns>`

## Output Interpretation

After running commands, provide:
1. **Status summary**: "3 pods running, 1 pending"
2. **Issues found**: Highlight problems with specific line references
3. **Suggested actions**: Next debugging steps or fixes
4. **Context**: Why this matters (e.g., "Service has no endpoints means no pods match the selector")

## Error Handling

**Common errors and responses:**

- **"No resources found"**:
  - Check namespace
  - Verify resource name spelling
  - Try `--all-namespaces` to find it

- **"Unauthorized"**:
  - Check RBAC permissions
  - Verify kubeconfig is correct
  - Try `kubectl auth can-i <verb> <resource>`

- **"Context not found"**:
  - List available contexts: `kubectl config get-contexts`
  - Set context: `kubectl config use-context <name>`

## Best Practices

1. **Use namespaces explicitly** unless user clearly means current namespace
2. **Prefer wide output** (`-o wide`) for initial inspection
3. **Show recent events** when resources aren't healthy
4. **Tail logs** (don't dump entire log history)
5. **Dry-run first** for apply/create/delete operations
6. **Verify after changes** to confirm expected state
7. **Use labels** for filtering when appropriate

## Resource Shortcuts

Teach kubectl short names when relevant:
- `po` = pods
- `deploy` = deployments
- `svc` = services
- `cm` = configmaps
- `secret` = secrets
- `ing` = ingresses
- `ns` = namespaces
- `no` = nodes

Example: `kubectl get po -n kube-system` instead of `kubectl get pods -n kube-system`

## Advanced Queries

For complex filtering and formatting:

```bash
# Get pods by label
kubectl get pods -l app=myapp -n <namespace>

# Custom columns
kubectl get pods -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName

# JSONPath queries
kubectl get pods -o jsonpath='{.items[*].metadata.name}'

# Sort by creation time
kubectl get pods --sort-by=.metadata.creationTimestamp
```

## Integration with Other Tools

When appropriate, suggest:
- **stern**: Multi-pod log tailing
- **k9s**: Interactive cluster management
- **kubectx/kubens**: Fast context/namespace switching
- **helm**: If dealing with Helm releases

Example: "For tailing logs from multiple pods, consider using `stern <pattern> -n <namespace>`"

## Safety Checks

Before destructive operations (delete, drain, etc.):
1. ⚠️ **Show what will be affected**
2. ⚠️ **Confirm cluster context**
3. ⚠️ **Wait for explicit user confirmation**
4. ⚠️ **Suggest non-destructive alternatives if available**

Never auto-execute:
- `kubectl apply` (always confirm first)
- `kubectl delete` (without confirmation)
- `kubectl drain`
- `kubectl cordon`
- `kubectl scale` (confirm before scaling)
- `kubectl rollout restart` (confirm before restarting)
- `kubectl exec` (confirm before executing commands in pods)
- Changing production contexts

## Examples

**User:** "check pods in production"
**Action:**
1. Verify context: `kubectl config current-context`
2. Get pods: `kubectl get pods -n production -o wide`
3. Highlight any non-Running pods
4. If issues found, offer to investigate further

**User:** "why is my-app pod crashing?"
**Action:**
1. Get pod status: `kubectl get pod my-app -n <namespace> -o wide`
2. Describe pod: `kubectl describe pod my-app -n <namespace>`
3. Check current logs: `kubectl logs my-app -n <namespace> --tail=100`
4. Check previous logs: `kubectl logs my-app -n <namespace> --previous --tail=100`
5. Analyze output and suggest fixes

**User:** "apply deployment.yaml"
**Action:**
1. Show file contents (if not already visible)
2. Dry-run: `kubectl apply -f deployment.yaml --dry-run=client`
3. Explain what will change
4. **Wait for explicit user confirmation** (always required for apply)
5. Apply: `kubectl apply -f deployment.yaml`
6. Verify: Check deployment status

## Notes

- This skill focuses on read operations and safe commands
- For write operations (delete, edit), always confirm with user
- Adapt namespace usage based on user's working context
- When in doubt, show current context and available resources
- Combine kubectl commands with analysis - don't just run commands blindly
