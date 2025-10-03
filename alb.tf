#############################################################################
# Managed the Loadbalancer for the Web Servers CDN will be in front shortly
#############################################################################

# Load balancer for Web Servers
resource "aws_lb" "alb" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets = data.aws_subnets.subnets.ids

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# Access to ALB from Internet. HTTPS only
resource "aws_security_group" "alb_sg" {
  vpc_id = data.aws_vpc.default_vpc.id
  name   = "${var.project_name}-alb-sg"

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = "443"
    to_port     = "443"
    protocol    = "tcp"
    description = "Allow HTTPS Inbound"
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

# Connection from ALB to Web Servers. uses HTTP (Unsecure)
resource "aws_lb_target_group" "alb_tg" {
  name     = "${var.project_name}-alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default_vpc.id

  health_check {
    path                = "/health-check.html"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }

  load_balancing_algorithm_type = "least_outstanding_requests"

  stickiness {
    enabled = true
    type    = "lb_cookie"
  }

  tags = {
    "Name" = "${var.project_name}-alb-tg"
  }
}

# ALB listens only on HTTPS.
resource "aws_lb_listener" "alb_https" {
  # Must have valid certificate for this resource
  count = var.certs_validated ? 1 : 0

  load_balancer_arn = aws_lb.alb.arn
  port              = "443"
  protocol          = "HTTPS"

  # use custom cert or ACM cert
  certificate_arn = aws_acm_certificate.alb_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }

  tags = {
    Name = "${var.project_name}-alb-https"
  }
}
