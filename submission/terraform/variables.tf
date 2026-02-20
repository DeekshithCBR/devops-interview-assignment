variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
}

variable "site_id" {
  description = "Customer site identifier"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "video-analytics"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "management_cidr" {
  description = "CIDR block allowed for management access (SSH)"
  type        = string
  default     = "10.50.1.0/24"
}

# Node group sizing/configuration
variable "general_node_instance_types" {
  description = "List of instance types for the general-purpose node group"
  type        = list(string)
  default     = ["t3.medium", "t3.large"]
}

variable "general_node_min" {
  description = "Minimum size for the general node group"
  type        = number
  default     = 2
}

variable "general_node_desired" {
  description = "Desired size for the general node group"
  type        = number
  default     = 3
}

variable "general_node_max" {
  description = "Maximum size for the general node group"
  type        = number
  default     = 5
}

variable "gpu_node_instance_type" {
  description = "Instance type for the GPU inference node group"
  type        = string
  default     = "g4dn.xlarge"
}

variable "gpu_node_min" {
  description = "Minimum size for the GPU node group"
  type        = number
  default     = 1
}

variable "gpu_node_desired" {
  description = "Desired size for the GPU node group"
  type        = number
  default     = 1
}

variable "gpu_node_max" {
  description = "Maximum size for the GPU node group"
  type        = number
  default     = 2
}

# S3 buckets used by the application
variable "video_bucket_name" {
  description = "Name of the S3 bucket for video chunks"
  type        = string
  default     = "vlt-video-chunks-prod"
}

variable "model_bucket_name" {
  description = "Name of the S3 bucket for ML model artifacts"
  type        = string
  default     = "vlt-model-artifacts-prod"
}
