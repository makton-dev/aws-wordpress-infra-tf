#############################################################################
# Creates and Manages the RDS instance.
#############################################################################

# Generate a random password for RDS Master user
resource "random_password" "rds_pass" {
  length           = 16
  special          = true         # Include special characters
  upper            = true         # Include uppercase letters
  lower            = true         # Include lowercase letters
  numeric          = true         # Include numbers
  override_special = "!@#$%^&*()" # Customize special characters (optional)
}

# create secret for RDS root information
resource "aws_secretsmanager_secret" "rds_secret" {
  name                    = "${var.project_name}/rds-root"
  recovery_window_in_days = 0

  tags = {
    "Name" = "${var.project_name}/rds-root"
  }
}

# Populate secret
resource "aws_secretsmanager_secret_version" "secret_version" {
  secret_id = aws_secretsmanager_secret.rds_secret.id
  secret_string = jsonencode({
    root_user = var.rds_root
    root_pass = random_password.rds_pass.result
    endpoint  = aws_db_instance.rds_primary.endpoint
  })
}

# RDS is only accessable in the VPC. This is one reason for the jumpbox
resource "aws_security_group" "rds_sg" {
  name        = "${var.project_name}-rds-sg"
  description = "Security group for RDS services within VPS only"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default_vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name" = "${var.project_name}-rds-sg"
  }
}

# the database will be named the project name.
resource "aws_db_instance" "rds_primary" {
  identifier             = "${var.project_name}-db"
  skip_final_snapshot    = true
  allocated_storage      = 20
  engine                 = var.rds_engine
  engine_version         = var.rds_engine_version
  instance_class         = var.rds_instance_type
  username               = var.rds_root
  password               = random_password.rds_pass.result
  publicly_accessible    = false
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  tags = {
    "Name" = "${var.project_name}-db"
  }
}

# Read Replicas
resource "aws_db_instance" "rds_replics" {
  count = var.rds_replicas

  identifier             = "${var.project_name}-db-replica-${count.index}"
  skip_final_snapshot    = true
  allocated_storage      = 20
  engine                 = var.rds_engine
  engine_version         = var.rds_engine_version
  replicate_source_db    = aws_db_instance.rds_primary.id
  instance_class         = var.rds_instance_type
  username               = var.rds_root
  password               = random_password.rds_pass.result
  publicly_accessible    = false
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  tags = {
    "Name" = "${var.project_name}-db-replica-${count.index}"
  }
}
