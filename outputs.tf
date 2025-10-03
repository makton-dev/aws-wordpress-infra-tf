output "latest_ami" {
  description = "Latest AMI used"
  value = {
    AMI          = data.aws_ami.latest.id
    Name         = data.aws_ami.latest.name
    Publish_date = data.aws_ami.latest.creation_date
  }
}

output "rds_main_endpoint" {
  description = "Enpoint for the main RDS instance"
  value       = aws_db_instance.rds_primary.endpoint
}

output "rds_replica_endpoints" {
  description = "Enpoints for the replica RDS instances"
  value       = aws_db_instance.rds_replics[*].endpoint
}

output "site_cert_validation_record" {
  description = "This DNS record needs to be added to the domain for the Site cert to be issued for the CDN"
  value       = aws_acm_certificate.site_cert.domain_validation_options
}

output "alb_cert_validation_record" {
  description = "This DNS record needs to be added to the domain for the ALB cert to be issued for the ALB"
  value       = aws_acm_certificate.alb_cert.domain_validation_options
}

output "web_endpoints" {
  description = "Endpoint for the CDN to put as an A records with an alias."
  value = {
    alb = {
      dns = resource.aws_lb.alb.dns_name
      zone_id = resource.aws_lb.alb.zone_id
    }
    cdn = {
      dns = aws_cloudfront_distribution.cdn[0].domain_name
      zone_id = aws_cloudfront_distribution.cdn[0].hosted_zone_id
    }
  }
}
