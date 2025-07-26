terraform {
  required_providers {
    tls   = { source = "hashicorp/tls" }
    local = { source = "hashicorp/local" }
    random = { source = "hashicorp/random" }
  }
}

# 1. Generate a new 4096-bit RSA key
resource "tls_private_key" "deployer" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# 2. Random suffix so name collisions don’t bite you on re-apply
resource "random_id" "suffix" {
  byte_length = 2
}

# 3. Upload public key to AWS
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key-${random_id.suffix.hex}"
  public_key = tls_private_key.deployer.public_key_openssh
}

# 4. Write the private key PEM to disk
resource "local_file" "deployer_pem" {
  content         = tls_private_key.deployer.private_key_pem
  filename        = "${path.module}/deployer_key.pem"
  file_permission = "0600"
}
