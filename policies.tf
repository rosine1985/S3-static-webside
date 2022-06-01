# -----------------------------------------------------------------------------
# Resources: CodePipeline/policy
# -----------------------------------------------------------------------------

resource "aws_iam_role" "codepipeline_role" {
  name = var.codepipeline_role

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": [
            "codepipeline.amazonaws.com"
          ]
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }
EOF
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = var.codepipeline_policy_name
  role = aws_iam_role.codepipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObjectAcl",
          "cloudfront:GetInvalidation",
          "s3:List*",
          "s3:PutObject",
        ]
        Effect   = "Allow"
        Resource = [
          "${aws_s3_bucket.artifact_store.arn}",
          "${aws_s3_bucket.artifact_store.arn}/*",
          "${aws_s3_bucket.my-website.arn}",
          "${aws_s3_bucket.my-website.arn}/*",
        ]
      },
      {
        "Effect" = "Allow",
        "Action" = [
          "iam:PassRole",
          "sts:AssumeRole"
        ],
        "Resource" = "*"
      },
      {
        "Effect" = "Allow",
        "Action" = [
          "ssm:Get*",
          "ssm:Describe",
          "ssm:List*"
        ],
        "Resource" = "*"
      },
      {
        "Effect" = "Allow",
        "Action" = "codestar-connections:UseConnection",
        "Resource" = "${aws_codestarconnections_connection.static_pipeline_connection.arn}"
      },
      {
        "Effect" = "Allow",
        "Action" = [
          "logs:*"
        ], 
        "Resource" = "arn:aws:logs:*:*:*"
      },
      {
        "Effect" = "Allow",
        "Action" = [
          "lambda:InvokeAsync",
          "lambda:InvokeFunction"
        ],
        "Resource" = "*"
      }
    ]
  })
}

