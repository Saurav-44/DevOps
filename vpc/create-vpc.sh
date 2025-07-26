terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# ───────────────────────────────────────────────────────────────────────────────
# 1) Auto-generate an SSH keypair & register it in AWS
# ───────────────────────────────────────────────────────────────────────────────
resource "tls_private_key" "deployer" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "random_id" "suffix" {
  byte_length = 2
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key-${random_id.suffix.hex}"
  public_key = tls_private_key.deployer.public_key_openssh
}

resource "local_file" "deployer_pem" {
  content         = tls_private_key.deployer.private_key_pem
  filename        = "${path.module}/deployer_key.pem"
  file_permission = "0600"
}

# ───────────────────────────────────────────────────────────────────────────────
# 2) AWS provider & pull in the Default VPC
# ───────────────────────────────────────────────────────────────────────────────
provider "aws" {
  region = var.region
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

# ───────────────────────────────────────────────────────────────────────────────
# 3) Security Group in Default VPC
# ───────────────────────────────────────────────────────────────────────────────
resource "aws_security_group" "app_sg" {
  name        = "app-sg"
  description = "Allow SSH, HTTP and intra-VPC"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ───────────────────────────────────────────────────────────────────────────────
# 4) EC2 Instances using Default VPC subnets
# ───────────────────────────────────────────────────────────────────────────────
resource "aws_instance" "frontend" {
  ami                           = var.ami
  instance_type                 = var.instance_type
  subnet_id                     = data.aws_subnet_ids.default.ids[0]
  key_name                      = aws_key_pair.deployer.key_name
  associate_public_ip_address   = true
  vpc_security_group_ids        = [aws_security_group.app_sg.id]
  tags = { Name = "FRONTEND" }
}

resource "aws_instance" "backend" {
  ami                           = var.ami
  instance_type                 = var.instance_type
  subnet_id                     = data.aws_subnet_ids.default.ids[1]
  key_name                      = aws_key_pair.deployer.key_name
  associate_public_ip_address   = true
  vpc_security_group_ids        = [aws_security_group.app_sg.id]
  tags = { Name = "BACKEND" }
}

# ───────────────────────────────────────────────────────────────────────────────
# 5) SSH Provisioners (run your scripts on the instances)
# ───────────────────────────────────────────────────────────────────────────────
resource "null_resource" "provision_frontend" {
  depends_on = [aws_instance.frontend]

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file(local_file.deployer_pem.filename)
    host        = aws_instance.frontend.public_ip
  }

  provisioner "file" {
    source      = "../scripts/frontend.sh"
    destination = "/home/ec2-user/frontend.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x frontend.sh",
      "sudo ./frontend.sh ${var.dockerhub_user}",
    ]
  }
}

resource "null_resource" "provision_backend" {
  depends_on = [aws_instance.backend]

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file(local_file.deployer_pem.filename)
    host        = aws_instance.backend.public_ip
  }

  provisioner "file" {
    source      = "../scripts/backend.sh"
    destination = "/home/ec2-user/backend.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x backend.sh",
      "sudo ./backend.sh ${var.dockerhub_user}",
    ]
  }
}

# ───────────────────────────────────────────────────────────────────────────────
# 6) Outputs
# ───────────────────────────────────────────────────────────────────────────────
output "frontend_public_ip" {
  description = "Public IP of the frontend server"
  value       = aws_instance.frontend.public_ip
}

output "backend_private_ip" {
  description = "Private IP of the backend server"
  value       = aws_instance.backend.private_ip
}
