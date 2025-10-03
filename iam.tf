#############################################################################
# Manages IAM  Roles and policies for the project.
#############################################################################

# Assume role policy for Service Web Role
data "aws_iam_policy_document" "web_assume_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# Service Role for web server instances.
resource "aws_iam_role" "web_role" {
  name               = "${var.project_name}-web-role"
  assume_role_policy = data.aws_iam_policy_document.web_assume_policy.json

  tags = {
    "Name" = "${var.project_name}-web-role"
  }
}

# Assume role policy for Service JumpBox Role
data "aws_iam_policy_document" "jb_assume_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# Service role for JumpBox instances
resource "aws_iam_role" "jb_role" {
  name               = "${var.project_name}-jb-role"
  assume_role_policy = data.aws_iam_policy_document.jb_assume_policy.json

  tags = {
    "Name" = "${var.project_name}-jb-role"
  }
}
