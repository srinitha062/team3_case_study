provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket         = "neeha-s3bucket-1212"
    key            = "globalstate/s3/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "neeha-1212-dblocks"
    encrypt        = true
  }
}
