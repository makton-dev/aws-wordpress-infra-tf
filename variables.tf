#############################################################################
# Variables used through the Terraform Project.
#############################################################################

variable "project_name" {
  type        = string
  description = "Name of the Terraform project. This is used as a prepend to all created resources. Must be at least 3 characters and lowercase"

  validation {
    condition     = length(var.project_name) > 2 && can(regex("[a-z]", var.project_name))
    error_message = "Must be at least 3 characters and lowercase only"
  }
}

variable "domain_name" {
  type        = string
  description = "FQDN for project website and dns. Used for setting up the CDN and Certificate"
}

variable "region" {
  type        = string
  description = "AWS region for the infrastructure"

  validation {
    condition     = can(regex("[a-z]{2}-[a-z]+-[1-9]", var.region))
    error_message = "Must be formated for AWS region: IE - us-east-1"
  }
}

#######################
# ASG/EC2 Variables
#######################

variable "ami_architecture" {
  type        = string
  description = "All EC2 Instances use the same architecture. Default is arm64"
  default     = "arm64"
}

variable "jumpbox_instance_type" {
  type        = string
  description = "Instance type for the JumpBox. Default is t4g.micro"
  default     = "t4g.micro"
}

variable "webserver_instance_type" {
  type        = string
  description = "Instance type for the Web Servers. Default is t4g.small"
  default     = "t4g.small"
}

#######################
# RDS Variables
#######################

variable "rds_root" {
  type        = string
  description = "Master user for RDS service. Must be at least 3 characters and lowercase. default is dbadmin"
  default     = "dbadmin"

  validation {
    condition     = length(var.project_name) > 2 && can(regex("[a-z]", var.rds_root))
    error_message = "Must be at least 3 characters and lowercase only"
  }
}

variable "rds_instance_type" {
  type        = string
  description = "Instance type for RDS. Default is t4g.micro"
  default     = "db.t4g.micro"
}

variable "rds_replicas" {
  type        = number
  description = "Amount of RDS replicas. Default is 0"
  default     = 0
}

variable "rds_engine" {
  type        = string
  description = "Database type used. Defauit is mariadb"
  default     = "mariadb"
}

variable "rds_engine_version" {
  type        = string
  description = "Database version for selected DB engine: default is 11.8"
  default     = "11.8"
}

#######################
# CDN Variables
#######################

variable "whitelisted_cookies" {
  description = "List of cookies to be whitelisted (forwarded) from the CDN"
  type        = list(any)

  default = [
    "comment_author_*",
    "comment_author_email_*",
    "comment_author_url_*",
    "wordpress_*",
    "wordpress_logged_in_*",
    "wordpress_test_cookie",
    "wp-settings-*",
    "AWSALB*"
  ]
}

variable "cdn_price_class" {
  type        = string
  description = "Sets the procing class for CloudFront. Options: PriceClass_100 | PriceClass_200 | PriceClass_All. Default is PriceClass_100 being the cheapest and most restrictive"
  default     = "PriceClass_100"
}

variable "cdn_geo_whitelist" {
  type        = list(string)
  description = "Sets the whitelist for geo-locations to access the CDN. Default is US, Mexico, and Canada. you can find the codes at https://en.wikipedia.org/wiki/List_of_ISO_3166_country_codes"
  default     = ["US", "MX", "CA"]
}


#######################
# certificate Variables
#######################

variable "make_cert" {
  type        = bool
  description = "The tells the project to create the site certificate in ACM. You will need to update the domain's DNS records to validate the cert before using. Default is true"
  default     = true
}

variable "site_cert_alt_names" {
  type = list(string)
  description = "When making the Site ACM cert. This will add SAN addresses to the certificate"
  default = []
}
variable "acm_certificate_arn" {
  type        = string
  description = "If you are using your own cert. input the arn here and set [make_cert] to false for the ALB listner and the CDN. Default is blank"
  default     = ""
}

variable "certs_validated" {
  type        = bool
  description = "The CDN and ALB HTTPS Listner cannot be created till the certs they use is validated. Run this the first time with [false] when [make_cert] is true. then run again with this variable [true]"
  default     = true
}
