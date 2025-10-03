resource "aws_acm_certificate" "site_cert" {
  region            = "us-east-1" # Certificate needs to be in us-east-1 for CDN
  domain_name       = var.domain_name
  validation_method = "DNS"
  subject_alternative_names = var.site_cert_alt_names

  tags = {
    Name = "${var.project_name}-site-cert"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# This certificate is needed for the Load balancer as the Load balancer can be in any region. CDN cert can only be in us-east-1
resource "aws_acm_certificate" "alb_cert" {
  domain_name       = "origin.${var.domain_name}"
  validation_method = "DNS"


  tags = {
    Name = "${var.project_name}-alb-cert"
  }

  lifecycle {
    create_before_destroy = true
  }
}
