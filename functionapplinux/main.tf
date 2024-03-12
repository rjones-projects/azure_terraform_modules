data "azurerm_resource_group" "_" {
  name = var.resource_group_name
}

resource "azurerm_service_plan" "_" {
  for_each = var.app_service_plan_properties

  name                         = "sp-${var.project_name}-${var.name}-${var.environment}-${data.azurerm_resource_group._.location}"
  location                     = data.azurerm_resource_group._.location
  resource_group_name          = data.azurerm_resource_group._.name
  os_type                      = "Linux"
  sku_name                     = each.value.sku_name
  maximum_elastic_worker_count = each.value.maximum_elastic_worker_count
  worker_count                 = each.value.worker_count
  per_site_scaling_enabled     = each.value.per_site_scaling_enabled
  zone_balancing_enabled       = each.value.zone_balancing_enabled
  tags                         = var.tags
  # app_service_environment_id = ??
}

data "azurerm_service_plan" "_" {
  name                = local.app_service_plan_name
  resource_group_name = data.azurerm_resource_group._.name
  depends_on          = [azurerm_service_plan._]
}

data "azurerm_storage_account" "_" {
  name                = var.storage_account_name
  resource_group_name = data.azurerm_resource_group._.name
}

resource "azurerm_linux_function_app" "_" {
  for_each = var.function_app_properties

  name                          = "fa-${var.project_name}-${var.name}-${var.environment}-${data.azurerm_resource_group._.location}"
  location                      = data.azurerm_resource_group._.location
  resource_group_name           = data.azurerm_resource_group._.name
  service_plan_id               = data.azurerm_service_plan._.id
  https_only                    = true
  app_settings                  = merge(local.default_application_settings, each.value.application_settings)

  storage_account {
    access_key   = data.azurerm_storage_account._.primary_access_key
    account_name = data.azurerm_storage_account._.name
    name         = "storage-account"
    share_name   = "function-app-${var.name}"
    type         = "AzureBlob"
  }

  site_config {
    always_on                   = length(regexall("Y1|P.+", data.azurerm_service_plan._.sku_name)) > 0 ? false : each.value.site_config.always_on
    application_insights_key    = var.application_insights_instrumentation_key
    ftps_state                  = each.value.site_config.ftps_state
    use_32_bit_worker           = each.value.site_config.use_32_bit_worker
    scm_use_main_ip_restriction = each.value.site_config.scm_use_main_ip_restriction
    health_check_path           = each.value.site_config.health_check_path
    http2_enabled               = true

    cors {
      allowed_origins     = each.value.cors.allowed_origins
      support_credentials = each.value.cors.support_credentials
    }
  }

  identity {
    type = each.value.identity.type
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      app_settings,
      tags,
      site_config[0].always_on
    ]
  }
}

data "azurerm_subnet" "function_app" {
  for_each = var.function_app_properties

  name                 = each.value.subnet_name
  virtual_network_name = each.value.vnet_name
  resource_group_name  = each.value.vnet_resource_group_name
}

resource "azurerm_app_service_virtual_network_swift_connection" "_" {
  for_each = var.function_app_properties

  app_service_id = azurerm_linux_function_app._[each.key].id
  subnet_id      = data.azurerm_subnet.function_app[each.key].id
}
