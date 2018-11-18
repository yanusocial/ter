provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
  }

#######
# Data
#######

data "aws_availability_zones" "all" {}

data "terraform_remote_state" "front" {
  backend = "s3"

  config {
    bucket = "terraform-state-jl"
    region = "${var.region}"
    key    = "front.tfstate"
  }
}

data "terraform_remote_state" "db" {
  backend = "s3"

  config {
    bucket = "terraform-state-jl"
    region = "${var.region}"
    key    = "db.tfstate"
  }
}

######
# EC2
######

resource "aws_instance" "dummy" {
  ami           = "ami-3548444c"
  instance_type = "${var.instance_type}"
  key_name      = "blog"
  tags          = { Name = "dummy" }
  vpc_security_group_ids = [ "${aws_security_group.all_http_traffic.id}" ]
  root_block_device      = { delete_on_termination = true }
  user_data = <<-EOF
	#!/bin/bash
	sudo yum -y update
	EOF
}

##################
# Security Groups
##################

resource "aws_security_group" "lb" {
  name = "lb"
  ingress {
    from_port = "443"
    to_port   = "443"
    protocol  = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
  ingress {
    from_port = "80"
    to_port   = "80"
    protocol  = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
  tags = { Name = "lb" }
  lifecycle = { create_before_destroy = true }
}

resource "aws_security_group" "all_http_traffic" {
  name = "all http traffic"
  ingress {
    from_port = "443"
    to_port   = "443"
    protocol  = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
  tags = { Name = "all http traffic" }
  lifecycle = { create_before_destroy = true }
}

##############
# Autoscaling
##############

resource "aws_launch_configuration" "launch_configuration" {
  image_id = "ami-3548444c"
  instance_type = "${var.instance_type}"
  security_groups = ["${aws_security_group.all_http_traffic.id}"]
  root_block_device = { delete_on_termination = true }
  lifecycle = { create_before_destroy = true }
}

resource "aws_autoscaling_group" "autoescalado" {
  launch_configuration = "${aws_launch_configuration.launch_configuration.id}"
  availability_zones   = ["${data.aws_availability_zones.all.names}"]
  
  min_size          = 1
  max_size          = 2
  desired_capacity  = 2
  tag = { 
    key                 = "Name"
    value               = "Dummy_autoscaling"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_attachment" "attachment" {
  alb_target_group_arn   = "${aws_lb_target_group.target_group.arn}"
  autoscaling_group_name = "${aws_autoscaling_group.autoescalado.id}"
}

resource "aws_alb_target_group_attachment" "instance_dummy" {
  target_group_arn = "${aws_lb_target_group.target_group.arn}"
  target_id        = "${aws_instance.dummy.id}"  
  port             = 443
}

######
# ELB
######

resource "aws_lb" "balanceador" {
  name               = "balanceador"
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.lb.id}"]
  subnets            = ["subnet-59e78a11", "subnet-1b13cc41", "subnet-95e27ff3"]
  enable_cross_zone_load_balancing = true
  tags { Name = "lb" }
}

resource "aws_lb_listener" "lb_listener_80" {  
  load_balancer_arn = "${aws_lb.balanceador.arn}"  
  port              = "80"  
  protocol          = "HTTP"
  
  default_action {    
    target_group_arn = "${aws_lb_target_group.target_group.arn}"
    type             = "forward"  
  }
}

resource "aws_lb_listener" "lb_listener_443" {
  load_balancer_arn = "${aws_lb.balanceador.arn}"
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = "arn:aws:acm:eu-west-1:407742103297:certificate/a550a4e9-013d-42ca-976c-1b6fad552328"
  default_action {
    target_group_arn = "${aws_lb_target_group.target_group.arn}"
    type             = "forward"
  }
}

resource "aws_lb_target_group" "target_group" {
  name                 = "targetgroup"
  vpc_id               = "vpc-37f4d451"
  port                 = "443"
  protocol             = "HTTPS"

  health_check {
    interval            = "20"
    path                = "/"
    protocol            = "HTTPS"
    port                = "443"
    healthy_threshold   = "3"
    unhealthy_threshold = "3"
    matcher             = "400-499"
  }

  lifecycle { create_before_destroy = true }
}

##############
# State on S3
##############

terraform {
  backend "s3" {
  encrypt = true
  bucket = "terraform-state-jl"
  region = "eu-west-1"
  key = "front.tfstate"
  }
}

resource "aws_efs_file_system" "default" {
  creation_token = "elastic_file_system"

  tags {
    Name = "elastic_file_system"
  }
}
