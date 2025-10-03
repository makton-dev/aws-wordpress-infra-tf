############################################################
# This file creates SSH keypairs for EC2 instance and 
# Adds the Private Key to secrets manager
############################################################

# Generates the Private and Public keys
resource "tls_private_key" "ssh_private" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# create keypair in AWS for use with EC2 instances (JumpBox and Web Severs)
resource "aws_key_pair" "ssh_keypair" {
  key_name   = "${var.project_name}-ssh"
  public_key = tls_private_key.ssh_private.public_key_openssh
  tags = {
    "Name" = "${var.project_name}-ssh"
  }
}

resource "aws_secretsmanager_secret" "ssh_private_secret" {
  name                    = "${var.project_name}/ssh-private"
  recovery_window_in_days = 0
  tags = {
    Name = "${var.project_name}/ssh-private"
  }
}

resource "aws_secretsmanager_secret_version" "ssh_private_secret_ver" {
  secret_id     = aws_secretsmanager_secret.ssh_private_secret.id
  secret_string = tls_private_key.ssh_private.private_key_openssh
}
