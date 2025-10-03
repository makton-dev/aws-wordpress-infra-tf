#############################################################################
# This Handles the "JumpBox" ECS Instance for accessing the Web Servers, 
# EFS filesystem and RDS Database for the Project.
# The "JumpBox" server is the only way to access these resources externally.
#############################################################################

# Launch Template for the JumpBox. It adds the needed apps for accessing
# the other resources in the project
resource "aws_launch_template" "jb_asg_template" {
  name = "${var.project_name}-jb-asg-template"

  image_id      = data.aws_ami.latest.id # latest Amazon Linux 2023
  instance_type = var.jumpbox_instance_type

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 20
    }
  }

  iam_instance_profile {
    arn = aws_iam_instance_profile.jb_role_profile.arn
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.jb_sg.id]
  }

  key_name = aws_key_pair.ssh_keypair.key_name

  # User data script to install software and mount the storage
  user_data = base64encode(local.jb_launch_script)

  tags = {
    Name = "${var.project_name}-jb-asg-template"
  }
}

# Using an Autoscale Group (ASG) for maintaining the Jumpbox EC2 Instance
resource "aws_autoscaling_group" "jb_asg" {
  name             = "${var.project_name}-jb-asg"
  desired_capacity = 1
  max_size         = 1
  min_size         = 1
  vpc_zone_identifier = data.aws_subnets.subnets.ids

  launch_template {
    id      = aws_launch_template.jb_asg_template.id
    version = "$Latest"
  }

  # Health check configuration
  health_check_type         = "EC2" # use "ELB" to have the health check be from the load balance
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "${var.project_name}-jb-asg"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [ aws_efs_access_point.efs_access ]
}

# Network Security Group for the Instance. This is how the Instance is public. SSH Only
resource "aws_security_group" "jb_sg" {
  name   = "${var.project_name}-jb-sg"
  vpc_id = data.aws_vpc.default_vpc.id

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    description = "Allow SSH Inbound"
  }

  tags = {
    Name = "${var.project_name}-jb-sg"
  }
}

# This creates an Instance Profile that is used by the Jumpbox for access needed resources by the 
# instance without adding creds.
resource "aws_iam_instance_profile" "jb_role_profile" {
  name = "${var.project_name}-jb-role-profile"
  role = aws_iam_role.jb_role.name
  tags = {
    "Name" = "${var.project_name}-jb-role-profile"
  }
}
