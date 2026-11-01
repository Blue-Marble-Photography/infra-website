# State lives in the site's own account (infra-remote-state); run with AWS_PROFILE=bluemarblephotography locally.
terraform {
  backend "s3" {
    bucket       = "tf-state-20261101160134250900000001"
    encrypt      = true
    key          = "infra-website/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}
