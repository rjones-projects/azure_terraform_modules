#----------------------------------------------
# Locals variables block for hardcoded values. 
#----------------------------------------------
locals {
  resource_group_name           = lower(var.resource_group_name)
  location                      = var.location
  base_name                     = "${var.project_name}-${var.environment}-${var.location}"
  networkprofileName            = "np-${local.base_name}"
  acgName                       = "acg-${local.base_name}"
  aciName                       = "aci-${local.base_name}"
  existingAppPlanName           = "ASP-RGGravTemp-ace1"
  existingStorageAccountName    = "zvcgravtemp"
  existingContainerName         = "grav-config"
  env_variables = var.env_variables
  tags     = merge({ "ResourceName" = format("%s", var.resource_group_name) }, var.tags, )
}

#---------------------------------------------------------
# Resource Group Creation or selection - Default is "false"
#----------------------------------------------------------
data "azurerm_resource_group" "rgrp" {
  count = var.create_resource_group==false ? 1 : 0
  name  = local.resource_group_name
}

resource "azurerm_resource_group" "rg" {
  count    = var.create_resource_group==true ? 1 : 0
  name     = local.resource_group_name
  location = local.location
  tags     = local.tags
}

resource "azurerm_container_group" "containergroup" {
  name                = local.acgName
  location            = local.location
  resource_group_name = local.resource_group_name
  dns_name_label      = var.dns_name
  os_type             = "Linux"
  ip_address_type       = "Private"
  subnet_ids = [var.subnet.id]

  image_registry_credential {
      username      = var.registry_username
      password      = var.registry_pass
      server        = var.registry_url
  }

  container {
    name   = local.acgName
    image  = var.image_name
    cpu    = var.cpu
    memory = var.memory
    ports {
      port     = var.port
      protocol = var.protocol
    }
    environment_variables = local.env_variables
  }
  tags = local.tags
}
