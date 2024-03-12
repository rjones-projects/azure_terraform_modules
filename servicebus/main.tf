data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

locals {
  namespace_name = "sbus-${var.project_name}-${var.environment}-${data.azurerm_resource_group.rg.location}"
}

resource "azurerm_servicebus_namespace" "namespace" {
  resource_group_name = data.azurerm_resource_group.rg.name
  name                = local.namespace_name
  location            = data.azurerm_resource_group.rg.location
  sku                 = var.namespace_sku
  capacity            = lower(var.namespace_sku) == "premium" ? var.namespace_capacity : 0
  zone_redundant      = lower(var.namespace_sku) == "premium" ? var.namespace_zone_redundancy : null
  tags                = var.tags
}

resource "azurerm_servicebus_queue" "queue" {
  for_each     = var.queues
  namespace_id = azurerm_servicebus_namespace.namespace.id
  name         = each.value.name

  default_message_ttl                  = length(each.value.default_message_ttl) > 0 ? each.value.default_message_ttl : null #ISO 8601 timespan duration of TTL of messages sent to this topic if no TTL value is set on the message itself.
  enable_express                       = length(each.value.enable_express) > 0 ? each.value.enable_express : null
  enable_partitioning                  = length(each.value.enable_partitioning) > 0 ? each.value.enable_partitioning : null #changing this forces a new resource to be created
  requires_duplicate_detection         = length(each.value.requires_duplicate_detection) > 0 ? each.value.requires_duplicate_detection : null
  lock_duration                        = length(each.value.lock_duration) > 0 ? each.value.lock_duration : null #ISO 8601 timespan duration of a peek-lock; Maximum value is 5 minutes. Defaults to 1 minute. (PT1M)
  max_size_in_megabytes                = length(each.value.max_size_in_megabytes) > 0 ? each.value.max_size_in_megabytes : null
  dead_lettering_on_message_expiration = length(each.value.dead_lettering_on_message_expiration) > 0 ? each.value.dead_lettering_on_message_expiration : null
  max_delivery_count                   = length(each.value.max_delivery_count) > 0 ? each.value.max_delivery_count : null
}

resource "azurerm_servicebus_topic" "topic" {
  for_each                     = lower(var.namespace_sku) != "basic" ? var.topics : {}
  namespace_id                 = azurerm_servicebus_namespace.namespace.id
  name                         = each.value.name
  status                       = each.value.status
  default_message_ttl          = length(each.value.default_message_ttl) > 0 ? each.value.default_message_ttl : null
  enable_express               = length(each.value.enable_express) > 0 ? each.value.enable_express : null
  enable_partitioning          = length(each.value.enable_partitioning) > 0 ? each.value.enable_partitioning : null #changing this forces a new resource to be created
  max_size_in_megabytes        = length(each.value.max_size_in_megabytes) > 0 ? each.value.max_size_in_megabytes : null
  requires_duplicate_detection = length(each.value.requires_duplicate_detection) > 0 ? each.value.requires_duplicate_detection : null #changing this forces a new resource to be created
  support_ordering             = length(each.value.support_ordering) > 0 ? each.value.support_ordering : null
}

resource "azurerm_servicebus_subscription" "subscription" {
  for_each                             = lower(var.namespace_sku) != "basic" ? var.subscriptions : {}
  name                                 = each.value.name
  topic_id                             = each.value.topic_id
  default_message_ttl                  = length(each.value.default_message_ttl) > 0 ? each.value.default_message_ttl : null
  lock_duration                        = length(each.value.lock_duration) > 0 ? each.value.lock_duration : null
  dead_lettering_on_message_expiration = length(each.value.dead_lettering_on_message_expiration) > 0 ? each.value.dead_lettering_on_message_expiration : null
  max_delivery_count                   = length(each.value.max_delivery_count) > 0 ? each.value.max_delivery_count : null
  enable_batched_operations            = length(each.value.enable_batched_operations) > 0 ? each.value.enable_batched_operations : null
  requires_session                     = length(each.value.requires_session) > 0 ? each.value.requires_session : null

  depends_on = [azurerm_servicebus_topic.topic]
}

resource "azurerm_servicebus_subscription_rule" "subscription_rule" {
  for_each     = lower(var.namespace_sku) != "basic" ? var.subscription_rules : {}

  name            = each.value.name
  subscription_id = each.value.subscription_id
  filter_type     = length(each.value.filter_type) > 0 ? each.value.filter_type : "SqlFilter"
  sql_filter      = length(each.value.filter) > 0 ? each.value.filter : "1=1"

  depends_on = [azurerm_servicebus_subscription.subscription]
}

resource "azurerm_servicebus_namespace_authorization_rule" "authorization_rule" {
  for_each     = var.authorization_rules
  namespace_id = azurerm_servicebus_namespace.namespace.id

  name = each.value.name

  listen = length(each.value.listen) > 0 ? each.value.listen : null
  send   = length(each.value.send) > 0 ? each.value.send : null
  manage = length(each.value.manage) > 0 ? each.value.manage : null
}

resource "azurerm_servicebus_namespace_network_rule_set" "network_rule" {
  for_each     = lower(var.namespace_sku) == "premium" ? var.network_rules : {}
  namespace_id = azurerm_servicebus_namespace.namespace.id

  default_action = each.value.default_action

  dynamic "network_rules" {
    for_each = toset(each.value.network_rule)
    content {
      subnet_id                            = network_rules.value.subnet_id
      ignore_missing_vnet_service_endpoint = network_rules.value.ignore_missing_vnet_service_endpoint
    }
  }

  ip_rules = each.value.ip_rules
}
