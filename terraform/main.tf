variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

variable "ami" {
  description = "AMI ID for Ubuntu"
  type        = string
  default     = "ami-0901f13eb74a20662" # Ubuntu 20.04 for eu-north-1
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "public_key_path" {
  description = "Path to public SSH key"
  type        = string
}

variable "private_key_path" {
  description = "Path to private SSH key"
  type        = string
}
