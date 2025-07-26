variable "region" { 
  description = "AWS region to deploy into" 
  default     = "eu-north-1" 
}

variable "vpc_cidr" { 
  description = "CIDR block for the VPC" 
  default     = "10.0.0.0/16" 
}

variable "public_cidr" { 
  description = "CIDR block for the public subnet" 
  default     = "10.0.1.0/24" 
}

variable "private_cidr" { 
  description = "CIDR block for the private subnet" 
  default     = "10.0.2.0/24" 
}

variable "ami" { 
  description = "Amazon Linux 2 or Ubuntu AMI ID" 
  default     = "ami-0abcdef1234567890" 
}

variable "instance_type" { 
  description = "EC2 instance type" 
  default     = "t2.micro" 
}

variable "dockerhub_user" { 
  description = "Your Docker Hub username" 
  default     = "saurav123"  # ← change this to your actual Docker ID
}
