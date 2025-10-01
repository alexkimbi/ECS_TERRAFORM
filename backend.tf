terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket-afrotech-grp3"
    key            = "state/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}