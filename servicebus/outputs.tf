output "primary_connection_strings" {
  value = { for name, values in azurerm_servicebus_namespace_authorization_rule.authorization_rule : name => values.primary_connection_string }
}
