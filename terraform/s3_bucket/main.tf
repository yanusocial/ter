provider "aws" {
  region = "eu-west-1"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-state-jl"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}

output "s3_bucket_arn" {
  value = "${aws_s3_bucket.terraform_state.arn}"
}

terraform {
  backend "s3" {
  encrypt = true
  bucket = "terraform-state-jl"
  region = "eu-west-1"
  key = "main.tfstate"
  key = "main.tfstate.backup"
  }
}
