# Multi-Cloud Weather Tracker

The project contains a static weather website and a Terraform workspace for the planned multi-cloud deployment.

## Project structure

- `website/` – frontend application and static assets
- `docs/` – architecture, screenshots, and troubleshooting guidance
- `terraform/` – Terraform configuration and provider lockfile

## Terraform setup

Copy `terraform/terraform.tfvars.example` to `terraform/terraform.tfvars` and replace the placeholder values with credentials from your cloud accounts. Never commit `terraform.tfvars` or credential files.

Existing local credential files are retained under `terraform/secrets/` with a `.tfvars.local` suffix so they are not auto-loaded; the directory remains ignored by Git.

## Website API key

Copy `website/config.js.example` to `website/config.js` and set your OpenWeatherMap API key before running the site or deploying it with Terraform. `website/config.js` is ignored by Git.

The key is delivered to browsers as part of this static site, so it is not a secret once deployed. Restrict it with the provider's available usage controls; use a backend proxy if the key must remain confidential.

The Terraform configuration provisions the AWS S3 and CloudFront site, Azure Storage failover site, and Route 53 health checks and DNS records.
