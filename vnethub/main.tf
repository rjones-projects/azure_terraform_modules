terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

#---------------------------------
# Local declarations
#---------------------------------
locals {
  resource_group_name = element(coalescelist(data.azurerm_resource_group.rgrp.*.name, azurerm_resource_group.rg.*.name, [""]), 0)
  location            = element(coalescelist(data.azurerm_resource_group.rgrp.*.location, azurerm_resource_group.rg.*.location, [""]), 0)
  if_ddos_enabled     = var.create_ddos_plan ? [{}] : []
  public_ip_map       = { for pip in var.public_ip_names : pip => true }
}
#---------------------------------------------------------
# Resource Group Creation or selection - Default is "true"
#----------------------------------------------------------
data "azurerm_resource_group" "rgrp" {
  count = var.create_resource_group == false ? 1 : 0
  name  = var.resource_group_name
}

resource "azurerm_resource_group" "rg" {
  count    = var.create_resource_group ? 1 : 0
  name     = lower(var.resource_group_name)
  location = var.location
  tags     = merge({ "ResourceName" = format("%s", var.resource_group_name) }, var.tags, )
}

#-------------------------------------
# VNET Creation - Default is "true"
#-------------------------------------
resource "azurerm_virtual_network" "vnet" {
  name                = lower("vnet-hub-${var.hub_vnet_name}-${local.location}-001")
  location            = local.location
  resource_group_name = local.resource_group_name
  address_space       = var.vnet_address_space
  dns_servers         = var.dns_servers
  tags                = merge({ "ResourceName" = lower("vnet-${var.hub_vnet_name}-${local.location}") }, var.tags, )

  dynamic "ddos_protection_plan" {
    for_each = local.if_ddos_enabled

    content {
      id     = azurerm_network_ddos_protection_plan.ddos[0].id
      enable = true
    }
  }
}

#--------------------------------------------
# Ddos protection plan - Default is "true"
#--------------------------------------------
resource "azurerm_network_ddos_protection_plan" "ddos" {
  count               = var.create_ddos_plan ? 1 : 0
  name                = lower("${var.hub_vnet_name}-ddos-protection-plan")
  resource_group_name = local.resource_group_name
  location            = local.location
  tags                = merge({ "ResourceName" = lower("${var.hub_vnet_name}-ddos-protection-plan") }, var.tags, )
}

#-------------------------------------
# Network Watcher - Default is "true"
#-------------------------------------
resource "azurerm_resource_group" "nwatcher" {
  count    = var.create_network_watcher != false ? 1 : 0
  name     = "NetworkWatcherRG"
  location = local.location
  tags     = merge({ "ResourceName" = "NetworkWatcherRG" }, var.tags, )
}

resource "azurerm_network_watcher" "nwatcher" {
  count               = var.create_network_watcher != false ? 1 : 0
  name                = "NetworkWatcher_${local.location}"
  location            = local.location
  resource_group_name = azurerm_resource_group.nwatcher.0.name
  tags                = merge({ "ResourceName" = format("%s", "NetworkWatcher_${local.location}") }, var.tags, )
}

#--------------------------------------------------------------------------------------------------------
# Subnets Creation with, private link endpoint/servie network policies, service endpoints and Deligation.
#--------------------------------------------------------------------------------------------------------
resource "azurerm_subnet" "snet" {
  for_each             = var.subnets
  name                 = lower(format("snet-%s-${local.location}", each.value.subnet_name))
  resource_group_name  = local.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = each.value.subnet_address_prefix
  service_endpoints    = lookup(each.value, "service_endpoints", [])
  # Applicable to the subnets which used for Private link endpoints or services 
  private_endpoint_network_policies_enabled = lookup(each.value, "private_endpoint_network_policies_enabled", null)
  private_link_service_network_policies_enabled  = lookup(each.value, "private_link_service_network_policies_enabled", null)

  dynamic "delegation" {
    for_each = each.value.delegation == null ? [] : each.value.delegation
    content {
      name = each.value.delegation.name
      service_delegation {
        name    = each.value.delegation.service_delegation.name
        actions = each.value.delegation.service_delegation.actions
      }
    }
  }
}

#-----------------------------------------------
# Network security group - Default is "false"
#-----------------------------------------------
resource "azurerm_network_security_group" "nsg" {
  for_each            = var.subnets
  name                = lower("nsg-${each.value.subnet_name}-${local.location}")
  resource_group_name = local.resource_group_name
  location            = local.location
  tags                = merge({ "ResourceName" = lower("nsg-${each.key}_in") }, var.tags, )
  dynamic "security_rule" {
    for_each = concat(lookup(each.value, "nsg_inbound_rules", []), lookup(each.value, "nsg_outbound_rules", []))
    content {
      name                       = security_rule.value[0] == "" ? "Default_Rule" : security_rule.value[0]
      priority                   = security_rule.value[1]
      direction                  = security_rule.value[2] == "" ? "Inbound" : security_rule.value[2]
      access                     = security_rule.value[3] == "" ? "Allow" : security_rule.value[3]
      protocol                   = security_rule.value[4] == "" ? "Tcp" : security_rule.value[4]
      source_port_range          = "*"
      destination_port_range     = security_rule.value[5] == "" ? "*" : security_rule.value[5]
      source_address_prefix      = security_rule.value[6] == "" ? element(each.value.subnet_address_prefix, 0) : security_rule.value[6]
      destination_address_prefix = security_rule.value[7] == "" ? element(each.value.subnet_address_prefix, 0) : security_rule.value[7]
      description                = "${security_rule.value[2]}_Port_${security_rule.value[5]}"
    }
  }
}

#-----------------------------------------------
#Associate the NSG with the Subnet
#-----------------------------------------------
resource "azurerm_subnet_network_security_group_association" "nsg-assoc" {
  for_each                  = var.subnets
  subnet_id                 = azurerm_subnet.snet[each.key].id
  network_security_group_id = azurerm_network_security_group.nsg[each.key].id
}

#-------------------------------------------------
# route_table to dirvert traffic through Firewall
#-------------------------------------------------
resource "azurerm_route_table" "rtout" {
  name                = "route-network-outbound"
  resource_group_name = local.resource_group_name
  location            = local.location
  tags                = merge({ "ResourceName" = "route-network-outbound" }, var.tags, )
}

resource "azurerm_subnet_route_table_association" "rtassoc" {
  for_each       = var.subnets
  subnet_id      = azurerm_subnet.snet[each.key].id
  route_table_id = azurerm_route_table.rtout.id
}

resource "azurerm_route" "rt" {
  name                   = lower("route-to-firewall-${var.hub_vnet_name}-${local.location}")
  resource_group_name    = var.resource_group_name
  route_table_name       = azurerm_route_table.rtout.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.firewall_private_ip_address
}

#----------------------------------------
# Private DNS Zone - Default is "true"
#----------------------------------------
resource "azurerm_private_dns_zone" "dz" {
  count               = var.private_dns_zone_name != null ? 1 : 0
  name                = var.private_dns_zone_name
  resource_group_name = local.resource_group_name
  tags                = merge({ "ResourceName" = format("%s", lower(var.private_dns_zone_name)) }, var.tags, )
}

resource "azurerm_private_dns_zone_virtual_network_link" "dzvlink" {
  count                 = var.private_dns_zone_name != null ? 1 : 0
  name                  = lower("${var.private_dns_zone_name}-link")
  resource_group_name   = local.resource_group_name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  private_dns_zone_name = azurerm_private_dns_zone.dz[0].name
  tags                  = merge({ "ResourceName" = format("%s", lower("${var.private_dns_zone_name}-link")) }, var.tags, )
}

#----------------------------------------------------------------
# Azure Role Assignment for Service Principal - current user
#-----------------------------------------------------------------
data "azurerm_client_config" "current" {}

resource "azurerm_role_assignment" "peering" {
  scope                = azurerm_virtual_network.vnet.id
  role_definition_name = "Network Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "dns" {
  scope                = azurerm_private_dns_zone.dz[0].id
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

#------------------------------------------
# Public IP resources for Azure Firewall
#------------------------------------------
# resource "random_string" "str" {
#   for_each = local.public_ip_map
#   length   = 6
#   special  = false
#   upper    = false
#   keepers = {
#     domain_name_label = each.key
#   }
# }

# resource "azurerm_public_ip_prefix" "pip_prefix" {
#   name                = lower("${var.hub_vnet_name}-pip-prefix")
#   location            = local.location
#   resource_group_name = local.resource_group_name
#   prefix_length       = 30
#   tags                = merge({ "ResourceName" = lower("${var.hub_vnet_name}-pip-prefix") }, var.tags, )
# }

# resource "azurerm_public_ip" "fw-pip" {
#   for_each            = local.public_ip_map
#   name                = lower("pip-${var.hub_vnet_name}-${each.key}-${local.location}")
#   location            = local.location
#   resource_group_name = local.resource_group_name
#   allocation_method   = "Static"
#   sku                 = "Standard"
#   public_ip_prefix_id = azurerm_public_ip_prefix.pip_prefix.id
#   domain_name_label   = format("%s%s", lower(replace(each.key, "/[[:^alnum:]]/", "")), random_string.str[each.key].result)
#   tags                = merge({ "ResourceName" = lower("pip-${var.hub_vnet_name}-${each.key}-${local.location}") }, var.tags, )
# }

#-----------------------------------------------
# Storage Account for Logs Archive
#-----------------------------------------------
resource "random_string" "uniquestor" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_storage_account" "storeacc" {
  name                      = format("st%s${resource.random_string.uniquestor.result}", lower(replace(var.hub_vnet_name, "/[[:^alnum:]]/", "")))
  resource_group_name       = local.resource_group_name
  location                  = local.location
  account_kind              = "StorageV2"
  account_tier              = "Standard"
  account_replication_type  = "GRS"
  enable_https_traffic_only = true
  min_tls_version           = "TLS1_2"
  tags                      = merge({ "ResourceName" = format("stdiaglogs%s", lower(replace(var.hub_vnet_name, "/[[:^alnum:]]/", ""))) }, var.tags, )
}

#-----------------------------------------------
# Log analytics workspace  for Logs analysis
#-----------------------------------------------
resource "random_string" "main" {
  length  = 8
  special = false
  keepers = {
    name = var.hub_vnet_name
  }
}

resource "azurerm_log_analytics_workspace" "logws" {
  name                = lower("logaws-${random_string.main.result}-${var.hub_vnet_name}-${local.location}")
  resource_group_name = local.resource_group_name
  location            = local.location
  sku                 = var.log_analytics_workspace_sku
  retention_in_days   = var.log_analytics_logs_retention_in_days
  tags                = merge({ "ResourceName" = lower("logaws-${random_string.main.result}-${var.hub_vnet_name}-${local.location}") }, var.tags, )
}

# #-----------------------------------------
# # Network flow logs for subnet and NSG
# #-----------------------------------------
# resource "azurerm_network_watcher_flow_log" "nwflog" {
#   for_each                  = var.subnets
#   network_watcher_name      = azurerm_network_watcher.nwatcher[0].id
#   name                      = "${azurerm_network_watcher.nwatcher[0].id}.log"
#   resource_group_name       = azurerm_resource_group.nwatcher[0].name # Must provide Netwatcher resource Group
#   network_security_group_id = azurerm_network_security_group.nsg[each.key].id
#   storage_account_id        = azurerm_storage_account.storeacc.id
#   enabled                   = true
#   version                   = 2
#   retention_policy {
#     enabled = true
#     days    = 0
#   }

#   traffic_analytics {
#     enabled               = true
#     workspace_id          = azurerm_log_analytics_workspace.logws.workspace_id
#     workspace_region      = local.location
#     workspace_resource_id = azurerm_log_analytics_workspace.logws.id
#     interval_in_minutes   = 10
#   }
# }

#---------------------------------------------------------------
# azurerm monitoring diagnostics - VNet, NSG, PIP, and Firewall
#---------------------------------------------------------------
resource "azurerm_monitor_diagnostic_setting" "vnet" {
  name                       = lower("vnet-${var.hub_vnet_name}-diag")
  target_resource_id         = azurerm_virtual_network.vnet.id
  storage_account_id         = azurerm_storage_account.storeacc.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logws.id
  log {
    category = "VMProtectionAlerts"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }
  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "nsg" {
  for_each                   = var.subnets
  name                       = lower("${each.key}-diag")
  target_resource_id         = azurerm_network_security_group.nsg[each.key].id
  storage_account_id         = azurerm_storage_account.storeacc.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logws.id

  dynamic "log" {
    for_each = var.nsg_diag_logs
    content {
      category = log.value
      enabled  = true

      retention_policy {
        enabled = false
      }
    }
  }
}

