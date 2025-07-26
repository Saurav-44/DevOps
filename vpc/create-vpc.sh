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
# Now your regular AWS provider & resources...
# ───────────────────────────────────────────────────────────────────────────────

provider "aws" {
  region = var.region
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags       = { Name = "main-vpc" }
}
