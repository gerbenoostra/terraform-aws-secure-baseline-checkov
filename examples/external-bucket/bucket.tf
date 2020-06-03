resource "aws_s3_bucket" "logs" {
  #checkov:skip=CKV_AWS_52:MFA Delete cannot be managed by terraform
  #checkov:skip=CKV_AWS_18:This is the access log, won't log access to it.
  #checkov:skip=CKV_AWS_21:Won't version the access log
  bucket        = var.audit_s3_bucket_name
  acl           = "private"
  force_destroy = true
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  versioning {
    enabled = true
  }
}

data "aws_iam_policy_document" "logs_bucket_policy" {
  statement {
    sid     = "AWSCloudTrailAclCheckForConfig"
    actions = ["s3:GetBucketAcl"]
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
    resources = [aws_s3_bucket.logs.arn]
  }

  statement {
    sid     = "AWSCloudTrailWriteForConfig"
    actions = ["s3:PutObject"]
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
    resources = ["${aws_s3_bucket.logs.arn}/config/AWSLogs/${data.aws_caller_identity.current.account_id}/Config/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    sid     = "AWSCloudTrailAclCheckForCloudTrail"
    actions = ["s3:GetBucketAcl"]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    resources = [aws_s3_bucket.logs.arn]
  }

  statement {
    sid     = "AWSCloudTrailWriteForCloudTrail"
    actions = ["s3:PutObject"]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    resources = ["${aws_s3_bucket.logs.arn}/cloudtrail/AWSLogs/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id
  policy = data.aws_iam_policy_document.logs_bucket_policy.json
}
