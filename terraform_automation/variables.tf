variable "cluster_name" {
  description = "Cluster name"
  type        = string
}

variable "eks_version" {
  default     = "1.17"
  type        = string
}

variable "my_public_ip" {
  description = "My public IP address"
  type        = string
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
}

variable "instance_type" {
  description = "AWS EC2 instance type for workers"
  type        = string
}

variable "ssh_key_name" {
  description = "SSH Key to access worker nodes"
  type        = string
}

variable "ssh_key_path" {
  description = "SSH Key to access worker nodes"
  type        = string
}
