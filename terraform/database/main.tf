provider "aws" {
  region = "eu-west-1"
}

resource "aws_db_instance" "db" {
  engine              = "mariadb"
  allocated_storage   = 8
  instance_class      = "db.t2.micro"
  name                = "db"
  username            = "user"
  password            = "${var.db_password}"
  skip_final_snapshot = true
}

##############
# State on S3
##############

terraform {
  backend "s3" {
  encrypt = true
  bucket  = "terraform-state-jl"
  region  = "eu-west-1"
  key     = "db.tfstate"
  }
}
