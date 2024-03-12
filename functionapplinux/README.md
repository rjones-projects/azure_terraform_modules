[[_TOC_]]

# Introduction

This terraform module is for creating an `azurerm_linux_function_app` resource, alongside supporting resources.

# Requirements

- Terraform >= 1.4.6
- [AzureRM provider](https://www.terraform.io/docs/providers/azurerm/) > 3.59.0
- Minimum **Contributor** access required at the resource group or subscription scope.

# Inputs

| Name                                     | Description                                                                                                                                                        | Type             | Default | Required |
| ---------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ---------------- | ------- | :------: |
| name                                     | The name of the application.                                                                                                                                       | `string`         | `N/A`   |   yes    |
| environment                              | The environment being deployed to.                                                                                                                                 | `string`         | `N/A`   |   yes    |
| project_name                             | The name of the project e.g. ccv/hgv. Changing this forces a new resource to be created.                                                                           | `string`         | `N/A`   |   yes    |
| app_service_plan_properties              | Function App Service Plan properties, to create a plan if not using an existing plan.                                                                              | `map(object())`  | `{}`    |    no    |
| app_service_plan_name                    | Name of the App Service Plan for Function App hosting, if using an existing service plan. Ignored if app_service_plan_properties is set.                           | `string`         | `N/A`   |    no    |
| application_insights_instrumentation_key | Application Insights instrumentation key for function logs, if using an existing application_insights instance. Ignored if application_insights_properties is set. | `string`         | `N/A`   |    no    |
| function_app_properties                  | Function App properties.                                                                                                                                           | `list(object())` | `N/A`   |   yes    |
| resource_group_name                      | Resource group name.                                                                                                                                               | `string`         | `N/A`   |   yes    |
| storage_account_name                     | Storage account name, if using an existing storage account. Ignored if storage_account_properties is set.                                                          | `string`         | `N/A`   |    no    |
| tags                                     | Tags to use.                                                                                                                                                       | `map()`          | `N/A`   |    no    |

# Usage Examples

## Example 1

Create an Azure function app with an existing app service plan.

``` ruby
module "linuxfunctionapp" {
  source                                   = "../../.."
  resource_group_name                      = "rg-test"
  name                                     = "notifications"
  environment                              = "dev"
  project_name                             = "hgv"
  app_service_plan_name                    = "test-service-plan"
  application_insights_instrumentation_key = "xxxxxxxxxxxxxxxxxxxxxxxxxxxx"

  function_app_properties = {
    function_app_1 = {
      application_settings = {
        key1 = "value1test"
        key2 = "value2test"
      }
      site_config = {
        always_on                   = true
        ftps_state                  = "Disabled"
        use_32_bit_worker           = false
        scm_use_main_ip_restriction = true
      }
      cors = {
        allowed_origins     = []
        support_credentials = false
      }
      identity = {
        type = "SystemAssigned"
      }
      subnet_name              = "subnet-name"
      vnet_name                = "vnet-name"
      vnet_resource_group_name = "vnet-rg"
    }
  }

  storage_account_name = "test-storage-account"

  tags = {
    tag1 = "value1"
  }
}
```

## Example 2

Create a function app with a plan.

``` ruby
module "linuxfunctionapp" {
  source                                   = "../../.."
  resource_group_name                      = "rg-test"
  name                                     = "notifications"
  environment                              = "dev"
  project_name                             = "hgv"
  application_insights_instrumentation_key = "xxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  
  app_service_plan_properties = [
    service_plan_1 = {
      sku_name                     = "Y1"
      maximum_elastic_worker_count = null
      worker_count                 = 1
      per_site_scaling_enabled     = false
      zone_balancing_enabled       = false
    }
  ]

  function_app_properties = [
    function_app_1 = {
      application_settings = {
        key1 = "value1test"
        key2 = "value2test"
      }
      site_config = {
        always_on                   = true
        ftps_state                  = "Disabled"
        use_32_bit_worker           = false
        scm_use_main_ip_restriction = true
      }
      cors = {
        allowed_origins     = []
        support_credentials = false
      }
      identity = {
        type = "SystemAssigned"
      }
      subnet_name              = "subnet-name"
      vnet_name                = "vnet-name"
      vnet_resource_group_name = "vnet-rg"
    }
  ]

  storage_account_name = "test-storage-account"

  tags = {
    tag1 = "value1"
  }
}
```
