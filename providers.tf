# Credentials come from the state account (local SSO profile or GitHub OIDC); resources still live in
# var.resources_account_id until the account migration, after which assume_role goes away.
provider "aws" {
  region = var.aws_region

  assume_role {
    role_arn     = "arn:aws:iam::${var.resources_account_id}:role/bluemarble-infra"
    session_name = "infra-website"
  }

  default_tags {
    tags = var.tags
  }
}
