#############################################################################
# This manages the Web Services for the project through an AutoScale group
#############################################################################

resource "aws_launch_template" "web_asg_template" {
  name = "${var.project_name}-web-asg-template"

  image_id      = data.aws_ami.latest.id # latest Amazon Linux 2023
  instance_type = var.webserver_instance_type

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 20
    }
  }

  iam_instance_profile {
    arn = aws_iam_instance_profile.web_role_profile.arn
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.web_sg.id]
  }

  key_name = aws_key_pair.ssh_keypair.key_name

  # User data script to install software
  user_data = base64encode(local.web_launch_script)

  tags = {
    Name = "${var.project_name}-web-asg-template"
  }

  depends_on = [aws_s3_object.launch_objects]
}

resource "aws_autoscaling_group" "ds_site_scale_group" {
  name             = "${var.project_name}-web-asg"
  desired_capacity = 1
  max_size         = 1
  min_size         = 1
  vpc_zone_identifier = data.aws_subnets.subnets.ids

  launch_template {
    id      = aws_launch_template.web_asg_template.id
    version = "$Latest"
  }

  # Health check configuration
  health_check_type         = "EC2" # use "ELB" to have the health check be from the load balancer
  health_check_grace_period = 300

  # connected the load balancer to the ASG
  target_group_arns = [aws_lb_target_group.alb_tg.arn]

  tag {
    key                 = "Name"
    value               = "${var.project_name}-web-asg"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [ aws_efs_access_point.efs_access ]
}

## This is the auto-scaling policies. commenting for the time being
# resource "aws_autoscaling_attachment" "ds_wordpress_scale_att" {
#   autoscaling_group_name = aws_autoscaling_group.ds_site_scale_group.name
#   lb_target_group_arn = aws_lb_target_group.ds_wordpress_alb_tg.arn
# }

# resource "aws_autoscaling_policy" "ds_wordpress_scale_up" {
#   name = "ds_wordpress_scale_up"
#   scaling_adjustment = 1
#   adjustment_type = "ChangeInCapacity"
#   autoscaling_group_name = aws_autoscaling_group.ds_site_scale_group.name
# }

# resource "aws_autoscaling_policy" "ds_wordpress_scale_down" {
#   name = "ds_wordpress_scale_down"
#   scaling_adjustment = -1
#   adjustment_type = "ChangeInCapacity"
#   autoscaling_group_name = aws_autoscaling_group.ds_site_scale_group.name
# }

# Network Security Group for the Instance. This is how the Instance is public. SSH Only
resource "aws_security_group" "web_sg" {
  name   = "${var.project_name}-web-sg"
  vpc_id = data.aws_vpc.default_vpc.id

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }

  ingress {
    cidr_blocks = [data.aws_vpc.default_vpc.cidr_block]
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    description = "Allow HTTP VPC only"
  }

  ingress {
    cidr_blocks = [data.aws_vpc.default_vpc.cidr_block]
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    description = "Allow SSH VPC only"
  }

  tags = {
    Name = "${var.project_name}-web-sg"
  }
}

# Create an instance profile using the Service Web Role
resource "aws_iam_instance_profile" "web_role_profile" {
  name = "${var.project_name}-web-role-profile"
  role = aws_iam_role.web_role.name

  tags = {
    "Name" = "${var.project_name}-web-role-profile"
  }
}
