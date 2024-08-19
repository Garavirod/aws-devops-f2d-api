###########
# Databse # 
###########

resource "aws_db_subnet_group" "main" {
  name = "${local.prefix}-main"
  // Rds can be run on multiple subnets using subnet groups
  // which means they would be available through both of
  // thease subnets
  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]

  tags = {
    Name = "${local.prefix}-db-subnet-group"
  }
}


resource "aws_security_group" "rds" {
  description = "Allow access to RDS database instance"
  name        = "${local.prefix}-rds-inboud-access"
  vpc_id      = aws_vpc.main.id
  ingress {
    protocol  = "tcp"
    from_port = 5432
    to_port   = 5432
  }

  tags = {
    Name = "${local.prefix}-db-security-group"
  }
}


resource "aws_db_instance" "main" {
  identifier                 = "${local.prefix}-db"
  db_name                    = "f2d"
  allocated_storage          = 20    // GB
  storage_type               = "gp2" // general propose
  engine                     = "postgres"
  engine_version             = "15.4"
  auto_minor_version_upgrade = true // ensure that  security fixes are automaticaly applied to; Breif amount of downtime
  instance_class             = "db.t4g.micro"
  username                   = var.db_username
  password                   = var.db_password
  skip_final_snapshot        = true // easily create or remove our environment dev and testing,false for real
  db_subnet_group_name       = aws_db_subnet_group.main.name
  multi_az                   = false // true for highgly avalible
  backup_retention_period    = 0     // 0 for testing only or testing and keep cost min
  vpc_security_group_ids     = [aws_security_group.rds.id]

  tags = {
    Name = "${local.prefix}-main"
  }
}
