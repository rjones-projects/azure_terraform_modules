locals {
  app_service_plan_properties_names = [for key, value in var.app_service_plan_properties : key]

  app_service_plan_name = length(var.app_service_plan_properties) == 0 ? var.app_service_plan_name : azurerm_service_plan._[local.app_service_plan_properties_names[0]].name

  default_application_settings = {
    WEBSITE_RUN_FROM_PACKAGE       = 1
    APPINSIGHTS_INSTRUMENTATIONKEY = var.application_insights_instrumentation_key
    AzureWebJobsDisableHomepage    = true
  }
}
