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

# The site's own account (508360653481): resources move here one at a time. No assume_role:
# credentials already start in this account.
provider "aws" {
  alias  = "site"
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}
