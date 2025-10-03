#############################################################################
# This manages the S3 bucket which will hold some site files/configs that
# are used for the launch scripts when the servers are spun up.
#############################################################################

# Bucket for cscript files
resource "aws_s3_bucket" "launch_files_bucket" {
  bucket        = "${var.project_name}-launch-files"
  force_destroy = true
  tags = {
    Name = "${var.project_name}-script-files"
  }
}

# Enable versioning to any file changes
resource "aws_s3_bucket_versioning" "launch_files_bucket_versioning" {
  bucket = aws_s3_bucket.launch_files_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# puts everything /script_files into S3 bucket
resource "aws_s3_object" "launch_objects" {
  for_each = fileset("script_files/", "*")
  bucket   = aws_s3_bucket_versioning.launch_files_bucket_versioning.id
  key      = each.value
  source   = "script_files/${each.value}"
  etag     = filemd5("script_files/${each.value}")
}

# Uploads the dynamic apache domain config to S3
resource "aws_s3_object" "apache_conf_object" {
  bucket  = aws_s3_bucket_versioning.launch_files_bucket_versioning.id
  key     = "${var.domain_name}.conf"
  content = local.apache_conf
}

# IAM Policy allowing roles to access the EFS FileSystem
resource "aws_iam_policy" "launch_files_bucket_policy" {
  name        = "${var.project_name}-launch-files-bucket-policy"
  description = "Provides access to the site config files in S3"
  policy      = data.aws_iam_policy_document.s3_scripts_policy_doc.json
  tags = {
    Name = "${var.project_name}-launch-files-bucket-policy"
  }
}

# IAM Policy Document providing the needed rights to the IAM Policy above
data "aws_iam_policy_document" "s3_scripts_policy_doc" {
  statement {
    sid    = "S3ScriptsBucketAccess"
    effect = "Allow"
    actions = [
      "s3:getobject",
      "s3:GetObjectAcl",
      "s3:GetObjectAttributes",
      "s3:GetBucketVersioning",
      "s3:ListBucket",
      "s3:ListBucketVersions"
    ]
    resources = [
      aws_s3_bucket.launch_files_bucket.arn,
      "${aws_s3_bucket.launch_files_bucket.arn}/*"
    ]
  }
}

# Attaches the IAM Policy to any roles that need it
resource "aws_iam_policy_attachment" "launch_files_bucket_policy_att" {
  name       = "${var.project_name}-launch-files-bucket-att"
  policy_arn = aws_iam_policy.launch_files_bucket_policy.arn
  roles = [
    aws_iam_role.jb_role.name,
    aws_iam_role.web_role.name
  ]
}
