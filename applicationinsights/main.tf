terraform {

}
#---------------------------------
# Local declarations
#---------------------------------
locals {
  resource_group_name = element(coalescelist(data.azurerm_resource_group.rgrp.*.name, azurerm_resource_group.rg.*.name, [""]), 0)
  location            = element(coalescelist(data.azurerm_resource_group.rgrp.*.location, azurerm_resource_group.rg.*.location, [""]), 0)
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

#---------------------------------------------------------
# Application Insights resoruces - Default is "true"
#----------------------------------------------------------
resource "azurerm_application_insights" "main" {
  for_each                              = var.application_insights_config
  name                                  = lower(format("appi-%s", each.key))
  location                              = local.location
  resource_group_name                   = local.resource_group_name
  application_type                      = each.value["application_type"]
  daily_data_cap_in_gb                  = each.value["daily_data_cap_in_gb"]
  daily_data_cap_notifications_disabled = each.value["daily_data_cap_notification_disabled"]
  retention_in_days                     = each.value["retention_in_days"]
  sampling_percentage                   = each.value["sampling_percentage"]
  disable_ip_masking                    = each.value["disable_ip_masking"]
  tags                                  = merge({ "ResourceName" = lower(format("appi-%s", each.key)) }, var.tags, )
}