module "ec2_nginx" {
  source            = "./ec2-nginx"
  region            = "eu-north-1"
  public_key_path   = "~/.ssh/id_rsa.pub"
  private_key_path  = "~/.ssh/id_rsa"
}
