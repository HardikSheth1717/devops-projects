resource "aws_instance" "controlplane-server" {
  ami = var.ec2_instance_ami
  instance_type = var.ec2_instance_type

  vpc_security_group_ids = [aws_security_group.ec2-instance-sg.id]
  subnet_id = aws_subnet.semaphore-subnet-z1.id
  associate_public_ip_address = true

  key_name = "my-new-pk"

  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = 30
  }

  tags = {
    Name = "controlplane-server"
  }

  # user_data = filebase64("../../scripts/ansible.sh")

  user_data = <<-EOT
    #!/bin/bash
    set -e

    sudo apt-add-repository -y ppa:ansible/ansible

    # Update package repositories
    sudo apt update

    # Install Ansible
    sudo apt install -y ansible

    sudo echo -e "[webservers]\nweb-server ansible_host=${aws_instance.web-server.private_ip} ansible_connection=ssh ansible_user=ubuntu" > /etc/ansible/hosts
  EOT
}

resource "aws_instance" "web-server" {
  ami = var.ec2_instance_ami
  instance_type = var.ec2_instance_type

  vpc_security_group_ids = [aws_security_group.ec2-instance-sg.id]
  subnet_id = aws_subnet.semaphore-subnet-z1.id
  associate_public_ip_address = true

  key_name = "my-new-pk"

  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = 30
  }

  tags = {
    Name = "web-server"
  }
}