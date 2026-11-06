# Credentials come from the site account (508360653481): the local SSO profile or GitHub OIDC
# (infra-aws-base). Every resource lives in that account.
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.default_tags
  }
}
