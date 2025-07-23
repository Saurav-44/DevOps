variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-north-1" # or leave out default and pass in tfvars
}
