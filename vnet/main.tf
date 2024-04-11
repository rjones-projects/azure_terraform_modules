terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 3.10.0"
    }
  }
}

#------------------------
# Local declarations
#------------------------
locals {
  resource_group_name = element(coalescelist(data.azurerm_resource_group.rgrp.*.name, azurerm_resource_group.rg.*.name, [""]), 0)
  location            = element(coalescelist(data.azurerm_resource_group.rgrp.*.location, azurerm_resource_group.rg.*.location, [""]), 0)
  if_ddos_enabled     = var.create_ddos_plan ? [{}] : []
}

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

#-------------------------------------
# VNET Creation 
#-------------------------------------

resource "azurerm_virtual_network" "vnet" {
  name                = var.vnetwork_name
  location            = local.location
  resource_group_name = local.resource_group_name
  address_space       = [var.vnet_address_space]
  dns_servers         = var.dns_servers
  tags                = merge({ "Name" = format("%s", var.vnetwork_name) }, var.tags, )

  dynamic "ddos_protection_plan" {
    for_each = local.if_ddos_enabled

    content {
      id     = azurerm_network_ddos_protection_plan.ddos[0].id
      enable = true
    }
  }
}

#--------------------------------------------
# Ddos protection plan - Default is "false"
#--------------------------------------------

resource "azurerm_network_ddos_protection_plan" "ddos" {
  count               = var.create_ddos_plan ? 1 : 0
  name                = var.ddos_plan_name
  resource_group_name = local.resource_group_name
  location            = local.location
  tags                = merge({ "Name" = format("%s", var.ddos_plan_name) }, var.tags, )
}

#-------------------------------------
# Network Watcher - Default is "true"
#-------------------------------------
resource "azurerm_resource_group" "nwatcher" {
  count    = var.create_network_watcher != false ? 1 : 0
  name     = "NetworkWatcherRG"
  location = local.location
  tags     = merge({ "Name" = "NetworkWatcherRG" }, var.tags, )
}

resource "azurerm_network_watcher" "nwatcher" {
  count               = var.create_network_watcher != false ? 1 : 0
  name                = "NetworkWatcher_${local.location}"
  location            = local.location
  resource_group_name = azurerm_resource_group.nwatcher.0.name
  tags                = merge({ "Name" = format("%s", "NetworkWatcher_${local.location}") }, var.tags, )
}

#--------------------------------------------------------------------------------------------------------
# Subnets Creation with, private link endpoint/service network policies, service endpoints and Deligation.
#--------------------------------------------------------------------------------------------------------

# resource "azurerm_subnet" "fw-snet" {
#   count                = var.firewall_subnet_address_prefix != null ? 1 : 0
#   name                 = "AzureFirewallSubnet"
#   resource_group_name  = local.resource_group_name
#   virtual_network_name = azurerm_virtual_network.vnet.name
#   address_prefixes     = var.firewall_subnet_address_prefix #[cidrsubnet(element(var.vnet_address_space, 0), 10, 0)]
#   service_endpoints    = var.firewall_service_endpoints
# }

# resource "azurerm_subnet" "gw_snet" {
#   count                = var.gateway_subnet_address_prefix != null ? 1 : 0
#   name                 = "GatewaySubnet"
#   resource_group_name  = local.resource_group_name
#   virtual_network_name = azurerm_virtual_network.vnet.name
#   address_prefixes     = var.gateway_subnet_address_prefix #[cidrsubnet(element(var.vnet_address_space, 0), 8, 1)]
#   service_endpoints    = ["Microsoft.Storage"]
# }

resource "azurerm_subnet" "snet" {
  for_each                                       = var.subnets
  name                                           = each.key
  resource_group_name                            = local.resource_group_name
  virtual_network_name                           = azurerm_virtual_network.vnet.name
  address_prefixes                               = [each.value.subnet_address_prefix]
  service_endpoints                              = lookup(each.value, "service_endpoints", null)
  private_endpoint_network_policies_enabled =  each.value.private_endpoint_network_policies_enabled
  private_link_service_network_policies_enabled  = each.value.private_link_service_network_policies_enabled

  dynamic "delegation" {
    for_each = each.value.delegation != null ? [0] : []
    content {
      name = each.value.delegation.name
      service_delegation {
        name    = lookup(each.value.delegation.service_delegation, "name", null)
        actions = lookup(each.value.delegation.service_delegation, "actions", null)
      }
    }
  }
  depends_on = [azurerm_virtual_network.vnet]
}

#-----------------------------------------------
# Network security group - Default is "false"
#-----------------------------------------------
resource "azurerm_network_security_group" "nsg" {
  for_each            = var.subnets
  name                = lower("nsg-${each.key}")
  resource_group_name = local.resource_group_name
  location            = local.location
  tags                = merge({ "ResourceName" = lower("nsg-${each.key}_in") }, var.tags, )
  dynamic "security_rule" {
    for_each = merge(each.value.nsg_inbound_rules, each.value.nsg_outbound_rules)
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
