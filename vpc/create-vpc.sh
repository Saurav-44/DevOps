provider "aws" {
  region = var.region
}

# 1. VPC & Subnets
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = { Name = "main-vpc" }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_cidr
  map_public_ip_on_launch = true
  tags = { Name = "public-subnet" }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_cidr
  map_public_ip_on_launch = true    # allow SSH provisioning
  tags = { Name = "private-subnet" }
}

# 2. Security Group (SSH + HTTP + intra-VPC)
resource "aws_security_group" "app_sg" {
  name        = "app-sg"
  description = "Allow SSH, HTTP and intra-VPC"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22; to_port = 22; protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80; to_port = 80; protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 0; to_port = 0; protocol = "-1"
    cidr_blocks = [var.vpc_cidr]
  }
  egress {
    from_port   = 0; to_port = 0; protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 3. EC2 Instances
resource "aws_instance" "frontend" {
  ami                         = var.ami
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  key_name                    = var.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.app_sg.id]
  tags = { Name = "FRONTEND" }
}

resource "aws_instance" "backend" {
  ami                         = var.ami
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private.id
  key_name                    = var.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.app_sg.id]
  tags = { Name = "BACKEND" }
}

# 4. Provision Frontend
resource "null_resource" "provision_frontend" {
  depends_on = [aws_instance.frontend]

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file(var.private_key_path)
    host        = aws_instance.frontend.public_ip
  }

  provisioner "file" {
    source      = "../scripts/frontend.sh"
    destination = "/home/ec2-user/frontend.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x frontend.sh",
      "sudo ./frontend.sh ${aws_instance.backend.private_ip} ${var.dockerhub_user}"
    ]
  }
}

# 5. Provision Backend
resource "null_resource" "provision_backend" {
  depends_on = [aws_instance.backend]

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file(var.private_key_path)
    host        = aws_instance.backend.public_ip
  }

  provisioner "file" {
    source      = "../scripts/backend.sh"
    destination = "/home/ec2-user/backend.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x backend.sh",
      "sudo ./backend.sh ${var.dockerhub_user}"
    ]
  }
}
