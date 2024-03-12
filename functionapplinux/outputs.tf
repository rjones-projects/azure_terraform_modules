output "app_service_plan_name" {
  value = local.app_service_plan_name
}

output "function_app_id" {
  value = [for v in azurerm_linux_function_app._ : v.id]
}

output "function_app_name" {
  value = [for v in azurerm_linux_function_app._ : v.name]
}

output "function_app_default_hostname" {
  value = [for v in azurerm_linux_function_app._ : v.default_hostname]
}
