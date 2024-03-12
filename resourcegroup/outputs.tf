
output "name" {
  description = "The name of the newly created RG"
  value       = azurerm_resource_group.rg.name
}

output "location" {
  description = "The location of the newly created RG"
  value       = azurerm_resource_group.rg.location
}

output "id"{
  description = "The id of the newly created RG"
  value       = azurerm_resource_group.rg.id
}