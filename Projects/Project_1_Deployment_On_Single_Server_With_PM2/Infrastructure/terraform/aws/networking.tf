# module "vpc" {
#   source = "terraform-aws-modules/vpc/aws"
#   name = "semaphore-vpc"
#   cidr = "10.0.0.0/16"

#   azs = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
#   private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
#   public_subnets = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

#   enable_vpn_gateway = true

#   tags = {
#     Name = "semaphore-vpc"
#   }
# }

# module "ec2_security_group" {
#     source = "terraform-aws-modules/security-group/aws"

#     name = "semaphore-ec2-sg"
#     description = "This security group will be used to allow required ports for EC2 instances."
#     vpc_id = module.vpc.vpc_id 

#     ingress_cidr_blocks = ["0.0.0.0/0"]
#     ingress_rules = ["http-80-tcp", "https-443-tcp", "ssh-tcp"]
#     egress_rules = ["all-all"]
# }

# module "rds_security_group" {
#     source = "terraform-aws-modules/security-group/aws"

#     name = "semaphore-rds-sg"
#     description = "This security group will be used to allow required ports for RDS instances."
#     vpc_id = module.vpc.vpc_id 

#     ingress_cidr_blocks = ["0.0.0.0/0"]
#     ingress_rules = ["mysql-tcp"]
#     egress_rules = ["all-all"]
# }

# resource "aws_db_subnet_group" "rds-subnet-group" {
#   name = "rds-subnet-group"
#   description = "RDS subnet group."
#   subnet_ids = [module.vpc.public_subnets[0], module.vpc.public_subnets[1], module.vpc.public_subnets[2]]

#   tags = {
#     Name = "rds-subnet-group"
#   }
# }

resource "aws_vpc" "semaphore-vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
  
  tags = {
    Name = "semaphore-vpc"
  }
}

resource "aws_internet_gateway" "semaphore-igw" {
  vpc_id = aws_vpc.semaphore-vpc.id

  tags = {
    Name = "semaphore-igw"
  }
}

resource "aws_subnet" "semaphore-subnet-z1" {
  vpc_id = aws_vpc.semaphore-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1a"
  
  tags = {
    Name = "semaphore-subnet-z1"
  }
}

resource "aws_subnet" "semaphore-subnet-z2" {
  vpc_id = aws_vpc.semaphore-vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-south-1b"
  
  tags = {
    Name = "semaphore-subnet-z2"
  }
}

resource "aws_route_table" "semaphore-rt" {
  vpc_id = aws_vpc.semaphore-vpc.id

  tags = {
    Name = "semaphore-rt"
  }
}

resource "aws_route" "semaphore-route" {
  route_table_id = aws_route_table.semaphore-rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.semaphore-igw.id
}

resource "aws_route_table_association" "semaphore-zone1-route-association" {
  route_table_id = aws_route_table.semaphore-rt.id
  subnet_id = aws_subnet.semaphore-subnet-z1.id
}

resource "aws_route_table_association" "semaphore-zone2-route-association" {
  route_table_id = aws_route_table.semaphore-rt.id
  subnet_id = aws_subnet.semaphore-subnet-z2.id
}

resource "aws_security_group" "ec2-instance-sg" {
  name = "ec2-instance-sg"
  vpc_id = aws_vpc.semaphore-vpc.id
  
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds-instance-sg" {
  name = "rds-instance-sg"
  vpc_id = aws_vpc.semaphore-vpc.id
  
  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "rds-subnet-group" {
  name = "rds-subnet-group"
  description = "RDS subnet group."
  subnet_ids = [aws_subnet.semaphore-subnet-z1.id, aws_subnet.semaphore-subnet-z2.id]

  tags = {
    Name = "rds-subnet-group"
  }
}