provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket         = "team3bucket1"
    key            = "globalstate/s3/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "team3_table"
    encrypt        = true
  }
}
