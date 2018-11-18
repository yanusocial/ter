output "lb_dns_name" {
  value = "${aws_lb.balanceador.dns_name}"
}

output "efs_name" {
  value = "${aws_efs_file_system.default.dns_name}"
}
