# GitLab-managed state; address and credentials are passed at `tofu init`.
terraform {
  backend "http" {}
}
