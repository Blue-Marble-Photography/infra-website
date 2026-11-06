terraform {
  required_version = "~> 1.11"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # State lives in the site's own account (infra-remote-state); run with AWS_PROFILE=bluemarblephotography locally.
  backend "s3" {
    bucket       = "tf-state-20261101160134250900000001"
    encrypt      = true
    key          = "infra-website/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}
