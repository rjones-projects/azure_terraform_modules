
#---------------------------------
# Local declarations
#---------------------------------
locals {
    resource_group_name = element(coalescelist(data.azurerm_resource_group.rgrp.*.name, azurerm_resource_group.rg.*.name, [""]), 0)
    location            = element(coalescelist(data.azurerm_resource_group.rgrp.*.location, azurerm_resource_group.rg.*.location, [""]), 0)
    sqlMiName   = "sqlmi-${var.projectName}-${var.environment}-${var.location}"
    tags        = merge({ "ResourceName" = format("%s", local.sqlMiName) }, var.tags, )
}

#---------------------------------------------------------
# Resource Group Creation or selection - Default is "false"
#----------------------------------------------------------

data "azurerm_resource_group" "rgrp" {
  count = var.create_resource_group == false ? 1 : 0
  name  = var.resource_group_name
}

resource "azurerm_resource_group" "rg" {
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
  tags     = merge({ "Name" = format("%s", var.resource_group_name) }, var.tags, )
}


resource "azurerm_mssql_managed_instance" "sqlmi" {
    name                = local.sqlMiName
    resource_group_name = local.resource_group_name
    location            = local.location

    #module policy defaults:
    license_type       = "BasePrice"
    sku_name           = "GP_Gen5"
    minimum_tls_version = 1.2


    storage_size_in_gb = var.storage_size_in_gb
    subnet_id          = var.subnet_id
    vcores             = var.vcores

    administrator_login          = var.admin_username
    administrator_login_password = var.admin_password
    tags = local.tags
}