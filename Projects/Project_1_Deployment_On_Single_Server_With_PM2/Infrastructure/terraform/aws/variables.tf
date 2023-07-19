variable "ec2_instance_name" {
  description = "Name of the ec2 instance."
  type = string
  default = "web-server"
}

variable "ec2_instance_type" {
  description = "Type of the ec2 instance."
  type = string
  default = "t2.medium"
}

variable "ec2_instance_ami" {
  description = "Name of the ec2 instance ami."
  type = string
  default = "ami-0f5ee92e2d63afc18"
}