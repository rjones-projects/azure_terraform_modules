resource "azurerm_mysql_server" "mysql_server" {
  location            = "${var.location}"
  resource_group_name = "${var.resource_group}"
  name                = "${var.name}"

  sku_name = "${var.Sku}"

  storage_mb                   = "${var.storage_mb}"
  auto_grow_enabled = true
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  administrator_login          = "${var.administrator_login}"
  administrator_login_password = "${var.administrator_login_password}"
  version                      = "8.0"
  public_network_access_enabled = true
  ssl_enforcement_enabled      = "${var.ssl_enforcement_enabled }"
  ssl_minimal_tls_version_enforced  = "${var.ssl_minimal_tls_version_enforced }"
  tags = "${var.tags}"

}
