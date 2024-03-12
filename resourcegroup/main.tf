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
    resourceGroupName  = "rg-${var.projectName}%{if var.environment!=""}-${var.environment}%{endif}-${var.location}"
    tags = {
    environment = "development"
    costcenter  = "it"
    "Created By"  = "Terraform"
    Owner = "john.poole@zenith.co.uk"
  }
}

 #Create the Resource Group
resource "azurerm_resource_group" "rg" {

    name     = local.resourceGroupName
    location = "${var.location}"
    tags = merge({ "ResourceName" = format("%s", local.resourceGroupName) }, local.tags, var.tags )
}