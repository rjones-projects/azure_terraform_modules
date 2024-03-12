output "id"{
  description = "The id of the newly created Identity"
  value       = azurerm_user_assigned_identity.Identity.id
}

output "principal_id"{
  description = "The principal_id of the newly created Identity"
  value       = azurerm_user_assigned_identity.Identity.principal_id
}

output "client_id"{
  description = "The client_id of the newly created Identity"
  value       = azurerm_user_assigned_identity.Identity.client_id
}