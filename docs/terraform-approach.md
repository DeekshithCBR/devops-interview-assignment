# Terraform Approach

The Terraform configuration builds a secure, production-grade VPC and
EKS cluster with two node groups. Key decisions:

* **Networking**: 2-AZ VPC with public and private subnets; NAT gateway in a
  public subnet.  Route tables corrected to avoid earlier bugs.  SSH
  access limited via `management_cidr` variable.
* **IAM Roles**: Separate roles for the EKS control plane and worker
  nodes, with least-privilege managed policy attachments.
* **Cluster**: Private subnets for nodes, public API endpoint, and
  logging enabled (`api`, `audit`, `authenticator`).  Kubernetes version
  pinned to 1.27.
* **Node groups**: General-purpose group using variable instance types
  and auto-scaling settings; GPU group tainted for inference workloads.
* **Variables/Outputs**: Parameterized sizing, S3 bucket names, and
  exported subnet IDs, NAT IPs, and bucket names for downstream use.
* **Cost optimization**: Lifecycle policy for the video chunks bucket and
  spot/mixed-instance launch template (see `cost_optimization.tf`).

Trade-offs:

* We select `t3` family for general workloads for cost efficiency, but
  workload characteristics may drive different choices.
* Spot instances reduce cost but require handling interruptions.  We
  isolate GPU workloads to their own group, limiting blast radius.

This modular layout allows adding additional resources (RDS, VPC
endpoints) without impacting the core cluster configuration.