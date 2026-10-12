# Azure Blob Storage hosts the secondary site used during Route53 failover.
# This configuration enables static website hosting and uploads the built site files into the
# Azure-managed "$web" container that serves the application.

resource "azurerm_resource_group" "rg" {
  name     = "rg-weather-static-website"
  location = var.azure_location
}

resource "azurerm_storage_account" "storage" {
  name                     = var.azure_storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  # Static website hosting and public traffic are enabled for the failover endpoint.
  public_network_access = "Enabled"

  custom_domain {
    name          = "www.${var.domain_name}"
    use_subdomain = true # indirect (asverify) validation
  }

  depends_on = [aws_route53_record.azure_asverify]
}

# Enabling static website hosting creates the special "$web" container that serves the site.
resource "azurerm_storage_account_static_website" "site" {
  storage_account_id = azurerm_storage_account.storage.id
  index_document     = "index.html"
}

locals {
  # Resource Manager ID of the Azure-managed "$web" container used for static hosting.
  web_container_id = "${azurerm_storage_account.storage.id}/blobServices/default/containers/$web"
}

resource "azurerm_storage_blob" "site_files" {
  for_each = local.site_files

  name                 = each.key
  storage_container_id = local.web_container_id
  type                 = "Block"
  content_type         = each.value
  source               = "${local.site_dir}/${each.key}"
  content_md5          = filemd5("${local.site_dir}/${each.key}")

  depends_on = [azurerm_storage_account_static_website.site]
}

resource "azurerm_storage_blob" "site_assets" {
  for_each = fileset("${local.site_dir}/assets", "**")

  name                 = "assets/${each.value}"
  storage_container_id = local.web_container_id
  type                 = "Block"
  content_type         = lookup(local.mime_types, lower(reverse(split(".", each.value))[0]), "application/octet-stream")
  source               = "${local.site_dir}/assets/${each.value}"
  content_md5          = filemd5("${local.site_dir}/assets/${each.value}")

  depends_on = [azurerm_storage_account_static_website.site]
}