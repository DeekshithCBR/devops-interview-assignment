# Kubernetes Approach

The Kubernetes manifests provision a robust video-processor workload.
Highlights:

* **ConfigMap** houses all application settings, keeping secrets out of
  the deployment.  Environment variables are injected via `envFrom`.
* **Deployment**:
  * Non-root user, read-only root filesystem, dropped capabilities.
  * Resource requests/limits ensure scheduler visibility and prevent
    noisy neighbors.
  * Liveness/readiness probes drive self-healing and rolling updates.
  * Anti-affinity constraints spread pods across nodes/azs for
    resiliency.
* **Service** is a simple ClusterIP fronting port 8080.
* **NetworkPolicy** explicitly allows ingress only from Kafka and cache
  pods, denying all else (default deny by absence of other policies).
  Egress is restricted to HTTPS, reducing lateral movement.
* **HPA** scales between 3–10 replicas based on CPU utilization (60%).
  Behavior settings smooth scaling and avoid oscillation.

This configuration is ready for production and can be templatized via
Helm or Kustomize for multi-environment deployment.