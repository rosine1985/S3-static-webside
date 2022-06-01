# -----------------------------------------------------------------------------
# Resources: s3-static-website/main
# -----------------------------------------------------------------------------

resource "aws_s3_bucket" "my-website" {
    bucket        = var.bucket_name
    force_destroy = true
    tags          = local.tags
}

resource "aws_s3_bucket_acl" "my_website_acl" {
  bucket = aws_s3_bucket.my-website.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "my_website_versioning" {
  bucket = aws_s3_bucket.my-website.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "my_website_bucket_encryption" {
  bucket = aws_s3_bucket.my-website.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "s3block" {
    bucket                    = aws_s3_bucket.my-website.id

    block_public_acls         = true
    block_public_policy       = true
    ignore_public_acls        = true
    restrict_public_buckets   = true
}

resource "aws_cloudfront_distribution" "cf" {
  enabled         = true
  
  default_root_object = "index.html"

  origin {
    domain_name = aws_s3_bucket.my-website.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.my-website.bucket_regional_domain_name

    s3_origin_config {
            origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
        }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  default_cache_behavior {
    target_origin_id = aws_s3_bucket.my-website.bucket_regional_domain_name

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 1800
    default_ttl            = 1800
    max_ttl                = 1800
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = local.tags
}

resource "aws_cloudfront_origin_access_identity" "oai" {
    comment = "OAI for ${var.endpoint}"
}

resource "aws_s3_bucket_policy" "s3policy" {
    bucket = aws_s3_bucket.my-website.id
    policy = data.aws_iam_policy_document.s3policy.json
}

# -----------------------------------------------------------------------------
# Resources: CodePipeline/main
# -----------------------------------------------------------------------------

resource "aws_s3_bucket" "artifact_store" {
  bucket        = var.artifacts_bucket_name
  force_destroy = true
  tags          = local.tags
}

resource "aws_s3_bucket_versioning" "artifact_store_versioning" {
  bucket = aws_s3_bucket.artifact_store.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_acl" "artifact_store_acl" {
  bucket = aws_s3_bucket.artifact_store.id
  acl    = "private"
}

resource "aws_s3_bucket_lifecycle_configuration" "artifact_store-lifecycle" {
  bucket = aws_s3_bucket.artifact_store.id

  rule {
    status = "Enabled"
    id = "rule-1"
    expiration {
      days = 5
    }
  }
}

resource "aws_codestarconnections_connection" "static_pipeline_connection" {
  name          = "static-pipeline-connection"
  provider_type = "GitHub"
}

resource "aws_codepipeline" "static_web_pipeline" {
  name     = var.pipeline_name
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.artifact_store.id
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.static_pipeline_connection.arn
        FullRepositoryId = var.github_repo_id
        BranchName       = var.source_branch
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      category = "Deploy"
      configuration = {
        "BucketName" = aws_s3_bucket.my-website.id
        "Extract"    = "true"
      }
      input_artifacts = ["source_output"]
      name             = "Deploy"
      output_artifacts = []
      owner            = "AWS"
      provider         = "S3"
      run_order        = 1
      version          = "1"
    }
  }

  stage {
    name = "Invalidate"

    action {
      category = "Invoke"
      configuration = {
        "FunctionName" = "Invalidate"
        "UserParameters" = jsonencode(
          {
            distributionId = "EX1OURBD0QXDE"
	          objectPaths    = ["/*"]
	        }
        )
      }
      input_artifacts = ["source_output"]
      name             = "Invalidate"
      output_artifacts = []
      owner            = "AWS"
      provider         = "Lambda"
      version          = "1"
      region           = "us-east-1"
    }
  }
}