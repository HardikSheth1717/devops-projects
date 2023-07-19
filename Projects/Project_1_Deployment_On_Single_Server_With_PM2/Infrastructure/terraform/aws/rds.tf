resource "aws_db_instance" "mysql-server" { 
    identifier = "mysql-db"
    db_name = "semaphore"
    engine = "mysql"
    username = "admin"
    password = "Semaphore123"
    allocated_storage = 20
    engine_version = "8.0.32"
    instance_class = "db.t2.medium"
    multi_az = false
    vpc_security_group_ids = [aws_security_group.rds-instance-sg.id]
    db_subnet_group_name = aws_db_subnet_group.rds-subnet-group.name
    port = 3306
    storage_type = "gp2"
    publicly_accessible = true
    tags = {
      "Name" = "mysql-db"
    }
    skip_final_snapshot = true
}
