output "ec2_controller_instance_id" {
  description = "Id of the controller instance."
  value = aws_instance.controlplane-server.id
}

output "ec2_controller_instance_public_ip" {
  description = "Public IP address of the controller instance."
  value = aws_instance.controlplane-server.public_ip
}

output "ec2_controller_instance_private_ip" {
  description = "Private IP address of the controller instance."
  value = aws_instance.controlplane-server.private_ip
}

output "ec2_web_server_instance_id" {
  description = "Id of the web server instance."
  value = aws_instance.web-server.id
}

output "ec2_web_server_instance_public_ip" {
  description = "Public IP address of the web server instance."
  value = aws_instance.web-server.public_ip
}

output "ec2_web_server_instance_private_ip" {
  description = "Private IP address of the web server instance."
  value = aws_instance.web-server.private_ip
}

output "rds_mysql_instance_id" {
  description = "Id of the MySQL RDS instance."
  value = aws_db_instance.mysql-server.id
}

output "rds_mysql_instance_endpoint" {
  description = "Public endpoint of the MySQL RDS instance."
  value = aws_db_instance.mysql-server.endpoint
}