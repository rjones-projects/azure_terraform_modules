# Service Bus

## Description

This terraform module is for creating Azure service bus, queues, topics, subscriptions, subscription rules  authorization rules and network rules

## Requirements

- [AzureRM Terraform provider](https://www.terraform.io/docs/providers/azurerm/) > 2.0.0
- Minimum **Contributor** access required at the resource group or subscription scope to create Service Bus and associated service bus entities

## Inputs

| Name                                    | Description                                                                                                                                                                                                                  | Type          | Default    | Required |
| --------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------- | ---------- | :------: |
| resource\_group\_name                   | The name of the resource group in which to create the resource. Changing this forces a new resource to be created                                                                                                            | `string`      | `N/A`      |   yes    |
| servicebus\_namespace\_name             | Specifies the name of the ServiceBus Namespace resource. Changing this forces a new resource to be created.Servicebus namespace name  can be of 6-50 characters length and should contain only letters, numbers and hyphens. | `string`      | `N/A`      |   yes    |
| servicebus\_namespace\_sku              | Defines which tier to use. Options are basic, standard or premium                                                                                                                                                            | `string`      | `standard` |   yes    |
| servicebus\_namespace\_capacity         | Specifies the capacity. When sku is Premium, capacity can be 1, 2, 4 or 8. When sku is Basic or Standard, capacity can be 0 only                                                                                             | `number`      | 0          |    no    |
| servicebus\_namespace\_zone\_redundancy | Whether or not this resource is zone redundant. sku needs to be Premium. Defaults to false                                                                                                                                   | `bool`        | `false`    |    no    |
| tags                                    | A mapping of tags to assign to the resource                                                                                                                                                                                  | `map(string)` | {}         |    no    |
| queues                                  | map of servicebus queues to create and associated queue properties                                                                                                                                                           | `map(any)`    | `{}`       |    no    |
| topics                                  | map of service bus topics to create and associated topic properties                                                                                                                                                          | `map(any)`    | `{}`       |    no    |
| subscriptions                           | map of service bus subscriptions to create and associated subscription properties                                                                                                                                            | `map`         | `{}`       |    no    |
| subscription\_rules                     | map of service bus subscription rules to create and associated subscription rule properties                                                                                                                                  | `map(any)`    | `{}`       |    no    |
| authorization\_rules                    | map of service bus authorization rules to create and associated claims properties                                                                                                                                            | `map(any)`    | `{}`       |    no    |
| network\_rules                          | map of service bus IP rules and vnet service endpoints to create. Supported only in premium tier. _Subnet delegation is not handled by the module_.                                                                          | `map(any)`    | `{}`       |    no    |

## Examples

Example 1: Create Azure Service Bus resource with Standard sku

```terraform
terraform {
  required_version = ">=0.12.0"
}

provider "azurerm" {
  features {}
  version                    = ">=2.0.0"
  skip_provider_registration = true
}

data "azurerm_resource_group" "test" {
  name = var.resource_group_name
}

module "servicebus" {
  source                               = "../"
  resource_group_name                  = "rg-test-001"
  servicebus_namespace_name            = "service-bus-test"
  servicebus_namespace_sku             = var.servicebus_namespace_sku
  servicebus_namespace_zone_redundancy = var.servicebus_namespace_sku == "premium" ? var.servicebus_namespace_zone_redundancy : false
  tags                                 = var.tags
}
```

Example 2: Create Service Bus with topics, queues, subscription, subscription rules, authorization rules and network rules. Enable Zone Redundancy.

```terraform
terraform {
  required_version = ">=0.12.0"
}

provider "azurerm" {
  features {}
  version                    = ">=2.0.0"
  skip_provider_registration = true
}

data "azurerm_resource_group" "test" {
  name = var.resource_group_name
}

module "servicebus" {
  source                               = "../"
  resource_group_name                  = data.azurerm_resource_group.test.name
  servicebus_namespace_name            = var.servicebus_namespace_name
  servicebus_namespace_sku             = var.servicebus_namespace_sku
  servicebus_namespace_capacity        = var.servicebus_namespace_capacity
  servicebus_namespace_zone_redundancy = var.servicebus_namespace_sku == "premium" ? var.servicebus_namespace_zone_redundancy : false
  tags                                 = var.tags
  queues                               = var.queues
  topics                               = var.topics
  subscriptions                        = var.subscriptions
  subscription_rules                   = var.subscription_rules
  authorization_rules                  = var.authorization_rules
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the resource. Changing this forces a new resource to be created"
  type        = string
  default     = "rg-test-001"
}

variable "servicebus_namespace_name" {
  description = "Specifies the name of the ServiceBus Namespace resource . Changing this forces a new resource to be created"
  type        = string
  default     = "service-bus-test"
}

variable "servicebus_namespace_sku" {
  description = "Defines which tier to use. Options are basic, standard or premium"
  type        = string
  default     = "premium"
}

variable "servicebus_namespace_capacity" {
  description = "Specifies the capacity. When sku is Premium, capacity can be 1, 2, 4 or 8. When sku is Basic or Standard, capacity can be 0 only"
  type        = number
  default     = 2
}

variable "servicebus_namespace_zone_redundancy" {
  description = "Whether or not this resource is zone redundant. sku needs to be Premium. Defaults to false."
  default     = true
}
variable "tags" {
  description = "A mapping of tags to assign to the resource"
  type        = map(string)
  default = {
    Environment        = "Development"
    ManagedByTerraform = "True"
  }
}

variable "queues" {
  description = "map of queues to create"
  default = {
    queue_1 = {
      name                                 = "testqueue"
      default_message_ttl                  = "P14D"
      enable_express                       = "false"
      enable_partitioning                  = "false"
      lock_duration                        = "PT1M"
      requires_duplicate_detection         = "false"
      max_size_in_megabytes                = "5120"
      dead_lettering_on_message_expiration = "true"
      max_delivery_count                   = "20"
    },
    queue_2 = {
      name                                 = "testqueue2"
      default_message_ttl                  = ""
      enable_express                       = "false"
      enable_partitioning                  = "false"
      lock_duration                        = "PT1M"
      requires_duplicate_detection         = "false"
      max_size_in_megabytes                = "2048"
      dead_lettering_on_message_expiration = "true"
      max_delivery_count                   = "10"
    }
  }
}

variable "topics" {
  description = "map of topics to create. Available only in standard or premium tier"
  default = {
    topic_1 = {
      name                         = "testtopic1"
      default_message_ttl          = "P14D"
      enable_express               = "false"
      enable_partitioning          = "false"
      status                       = "Active"
      requires_duplicate_detection = "false"
      max_size_in_megabytes        = "5120"
      support_ordering             = "false"
    },
    topic_2 = {
      name                         = "testtopic2"
      default_message_ttl          = "PT4H"
      enable_express               = "false"
      enable_partitioning          = "false"
      status                       = "Disabled"
      requires_duplicate_detection = "false"
      max_size_in_megabytes        = "2048"
      support_ordering             = "false"
    }
  }
}

variable "subscriptions" {
  description = "map of subscriptions to create. Available only in standard or premium tier"
  default = {
    subscription_1 = {
      name                                 = "testsubscription1"
      topic_id                             = "testtopic1"
      default_message_ttl                  = "P14D"
      lock_duration                        = "PT1M"
      dead_lettering_on_message_expiration = "true"
      max_delivery_count                   = "20"
      enable_batched_operations            = "false"
      requires_session                     = "false"
    },
    subscription_2 = {
      name                                 = "testsubscription2"
      topic_id                             = "testtopic2"
      default_message_ttl                  = "P14D"
      lock_duration                        = ""
      dead_lettering_on_message_expiration = ""
      max_delivery_count                   = "20"
      enable_batched_operations            = "false"
      requires_session                     = "false"
    }
  }
}

variable "subscription_rules" {
  description = "map of subscription rules to create"
  default = {
    subscription_rule_1 = {
      name            = "testsubscriptionrule1"
      subscription_id = "testsubscription1"
      filter_type     = "SqlFilter"
      filter          = "color='red'"
    },
    subscription_rule_2 = {
      name            = "testsubscriptionrule2"
      subscription_id = "testsubscription2"
      filter_type     = ""
      filter          = ""
    }
  }
}

variable "authorization_rules" {
  description = "map of authorization rules to create"
  default = {
    authorization_rule_1 = {
      name   = "sendonlyauthorizationrule"
      send   = "true"
      manage = "false"
      listen = "false"
    },
    authorization_rule_2 = {
      name   = "listenauthorizationrule"
      listen = "true"
      manage = "false"
      send   = "false"
    },
    authorization_rule_3 = {
      name   = "sendandlistenauthorizationrule"
      listen = "true",
      send   = "true"
      manage = "false"
    }
  }
}

variable "network_rules" {
  description = "map of authorization rules to create"
  default = {
    network_rule_set_1 = {
      default_action = "Deny"
      network_rule = [
        {
          subnet_id  = "/subscriptions/xxxxxxxxxxxx/resource_groups/xxxxxxxxxxxxxxx/providers/Microsoft.Network/virtualNetworks/xxxxxxx/subnets/xxxxxx"
          ignore_missing_vnet_service_endpoint = "true"
      }]
      ip_rules = ["xxx.xxx.xxx.xxx"]
    }
  }
}
```
