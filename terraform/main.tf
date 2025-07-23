provider "aws" {
  region = var.region
}

resource "aws_key_pair" "generated_key" {
  key_name   = "ec2-key"
  public_key = file(var.public_key_path)
}

resource "aws_security_group" "web_sg" {
  name_prefix = "web-sg-"

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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "nginx" {
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = aws_key_pair.generated_key.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  provisioner "file" {
    source      = "scripts/install_nginx.sh"
    destination = "/tmp/install_nginx.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_nginx.sh",
      "sudo /tmp/install_nginx.sh"
    ]
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.private_key_path)
    host        = self.public_ip
  }

  tags = {
    Name = "nginx-instance"
  }
}
