# Troubleshooting

## Terraform

- Run Terraform commands from the `terraform/` directory.
- If provider initialization fails, check network access and run `terraform init` again.
- Run `terraform validate` after adding or changing Terraform configuration.
- Confirm that `terraform/terraform.tfvars` contains valid local credentials and is not committed.

## Website

- Serve the `website/` directory with a local static web server and open `index.html`.
- Check the browser console and network panel if weather data or static assets fail to load.
