variable "access_key" { default = "########################" }
variable "secret_key" { default = "##########################################" }
variable "region" { default = "eu-west-1" }
variable "instance_type" { default = "t2.micro" }
variable "zones" {
  default = [ "eu-west-1a", "eu-west-1b", "eu-west-1c" ]
}
