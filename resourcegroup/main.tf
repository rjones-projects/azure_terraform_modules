 terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 3.10.0"
    }
  }
}

# Constructed names of resources
locals {
    resource_group_name  = "rg-${var.projectName}%{if var.environment!=""}-${var.environment}%{endif}-${var.location}"
    tags = {
    environment = "development"
    costcenter  = "it"
    "Created By"  = "Terraform"
    Owner = "john.poole@zenith.co.uk"
  }
}

 #Create the Resource Group
resource "azurerm_resource_group" "rg" {

    name     = local.resource_group_name
    location = "${var.location}"
    tags = merge({ "ResourceName" = format("%s", local.resource_group_name) }, local.tags, var.tags )
}