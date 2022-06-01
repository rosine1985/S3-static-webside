# -----------------------------------------------------------------------------
# Resources: s3-static-website/data
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "s3policy" {
  statement {
    actions = ["s3:GetObject"]

    resources = [
      aws_s3_bucket.my-website.arn,
      "${aws_s3_bucket.my-website.arn}/*"
    ]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.oai.iam_arn]
    }
  }
}