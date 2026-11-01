# infra-website

AWS infrastructure for [bluemarble.photography](https://bluemarble.photography).

## What it does

- Serves the site and the photos through two CloudFront distributions (`bluemarble.photography`, `images.bluemarble.photography`) backed by private S3 buckets.
- Resizes photos on demand: a missing size 404s, a Lambda@Edge redirects to the resize API, and the resize Lambda (`lambdas/resize-images`, SAM) creates the copy.
- Blocks AI crawlers at the edge and publishes AI opt-out headers and `robots.txt`.
- Hosts DNS (Route 53), the TLS certificate (ACM), and inbound email forwarding (SES).

## Key details

| Detail | Value |
|--------|-------|
| State | S3 (`infra-remote-state`), account 508360653481 |
| Resources | Account 530167849052, reached via the `bluemarble-infra` role |
| Depends on | `infra-remote-state`, `infra-aws-base` |
| CI / CD | `tofu-ci.yml` (plan on push/PR), `tofu-cd.yml` (apply on dispatch), `sam-deploy.yml` (resize Lambda) |
