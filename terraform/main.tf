variable "bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
}

variable "acl" {
  description = "Canned ACL to apply"
  type        = string
  default     = "private"
}

variable "tags" {
  description = "Tags to apply to the bucket"
  type        = map(string)
  default     = {}
}

variable "region" {
  description = "AWS region where the bucket will be created"
  type        = string
}
