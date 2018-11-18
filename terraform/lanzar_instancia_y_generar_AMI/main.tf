provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

#######
# Data
#######

data "terraform_remote_state" "AMI" {
  backend = "s3"

  config {
    bucket = "terraform-state-jl"
    region = "${var.region}"
    key    = "AMI.tfstate"
  }
}

######
# EC2
######

resource "aws_instance" "dummy" {
  ami                    = "ami-3548444c"
  instance_type          = "${var.instance_type}"
  key_name               = "blog"
  tags                   = { Name = "blog-AMI" }
  root_block_device      = { delete_on_termination = true }

  user_data = <<-EOF
	#!/bin/bash
	sudo yum -y update
	EOF
}

##########
# EC2 AMI
##########

resource "aws_ami_from_instance" "blog-AMI" {
  name                    = "blog-AMI"
  source_instance_id      = "${aws_instance.dummy.id}"
  snapshot_without_reboot = true
  tags                    = { Name = "blog-AMI" }
}

##############
# State on S3
##############

terraform {
  backend "s3" {
  encrypt = true
  bucket  = "terraform-state-jl"
  region  = "eu-west-1"
  key     = "AMI.tfstate"
  }
}
