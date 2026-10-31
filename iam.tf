data "aws_iam_policy" "AmazonSESFullAccess" {
  arn = "arn:aws:iam::aws:policy/AmazonSESFullAccess"
}

resource "aws_iam_role" "lambda_ses_forwarder" {
  name               = "lambda-ses-forwarder-${var.domain}"
  assume_role_policy = file("templates/iam-lambda-trust.json")
}

resource "aws_iam_role_policy" "lambda_ses_forwarder" {
  name   = "ses-forwarder"
  role   = aws_iam_role.lambda_ses_forwarder.id
  policy = templatefile("templates/iam-ses-forwarder-policy.json", { bucket = "${var.domain}-email" })
}

resource "aws_iam_role_policy_attachment" "lambda_ses_forwarder_ses_full_access" {
  role       = aws_iam_role.lambda_ses_forwarder.name
  policy_arn = data.aws_iam_policy.AmazonSESFullAccess.arn
}

resource "aws_iam_role" "lambda_at_edge" {
  name               = "${var.domain}-lambda-edge"
  assume_role_policy = file("templates/iam-lambda-edge-trust.json")
}

resource "aws_iam_role_policy" "lambda_at_edge_logs" {
  name   = "${var.domain}-logs"
  role   = aws_iam_role.lambda_at_edge.id
  policy = file("templates/iam-logs-policy.json")
}
