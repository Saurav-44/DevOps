variable "region"        { default = "eu-north-1" }
variable "vpc_cidr"      { default = "10.0.0.0/16" }
variable "public_cidr"   { default = "10.0.1.0/24" }
variable "private_cidr"  { default = "10.0.2.0/24" }
variable "ami"           { default = "ami-0abcdef1234567890" }   # Update to a Linux AMI in your region
variable "instance_type" { default = "t2.micro" }
variable "key_name"      { description = "Your EC2 key pair name" }
variable "private_key_path" {
  description = "Path to your private key file (for SSH provisioners)"
}
variable "dockerhub_user" { description = "saurav123" }
