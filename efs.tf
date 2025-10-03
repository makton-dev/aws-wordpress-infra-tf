#############################################################################
# This file handles the EFS storage for the WordPress Project
# EFS is needed to maintain matching site file data between many web servers
#############################################################################

# Network Security Group for EFS. EFS is only allowed with VPC. Is not Public
resource "aws_security_group" "efs_sg" {
  vpc_id = data.aws_vpc.default_vpc.id
  name   = "${var.project_name}-efs-sg"

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default_vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-efs-sg"
  }
}

# EFS FileSystem
resource "aws_efs_file_system" "efs" {
  creation_token = "${var.project_name}-efs"

  tags = {
    Name = "${var.project_name}-efs"
  }
}

# EFS Mount Targets in each availability zone
resource "aws_efs_mount_target" "ds_wordpress_efs_mnt" {
  
  for_each = toset(data.aws_subnets.subnets.ids)

  file_system_id = aws_efs_file_system.efs.id
  subnet_id      = each.value

  security_groups = [
    aws_security_group.efs_sg.id
  ]
}

# Access Point on EFS which maintains permissions of www-data and the ECS user account
resource "aws_efs_access_point" "efs_access" {
  file_system_id = aws_efs_file_system.efs.id
  posix_user {
    gid = "1000"
    uid = "48"
  }
  root_directory {
    creation_info {
      owner_gid   = "1000"
      owner_uid   = "48"
      permissions = "0775"
    }
    path = "/wp-sites"
  }
  tags = {
    Name = "${var.project_name}-efs-access"
  }
}

# IAM Policy allowing roles to access the EFS FileSystem
resource "aws_iam_policy" "efs_policy" {
  name        = "${var.project_name}-efs-policy"
  description = "Provides EFS access to WordPress FileSystem"
  policy      = data.aws_iam_policy_document.efs_policy_doc.json

  tags = {
    Name = "${var.project_name}-efs-policy"
  }
}

# IAM Policy Document providing the needed rights to the IAM Policy above
data "aws_iam_policy_document" "efs_policy_doc" {
  statement {
    sid    = "MountWordPressEFS"
    effect = "Allow"
    actions = [
      "elasticfilesystem:ClientWrite",
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:DescribeMountTargets"
    ]
    resources = [
      aws_efs_file_system.efs.arn
    ]
  }

  statement {
    sid    = "EC2Perms"
    effect = "Allow"
    actions = [
      "ec2:DescribeAvailabilityZones"
    ]
    resources = ["*"]
  }
}

# Attaches the IAM Policy to any roles that need it
resource "aws_iam_policy_attachment" "role_efs_att" {
  name       = "${var.project_name}-jb-role-efs-att"
  policy_arn = aws_iam_policy.efs_policy.arn
  roles = [
    aws_iam_role.jb_role.name,
    aws_iam_role.web_role.name
  ]
}
