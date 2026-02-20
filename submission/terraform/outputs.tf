output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "eks_cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = var.cluster_name
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

output "nat_gateway_ips" {
  description = "Elastic IP(s) attached to NAT gateway(s)"
  value       = [aws_eip.nat.public_ip]
}

output "video_bucket_name" {
  description = "Name of the video chunks S3 bucket"
  value       = var.video_bucket_name
}

output "model_bucket_name" {
  description = "Name of the model artifacts S3 bucket"
  value       = var.model_bucket_name
}
