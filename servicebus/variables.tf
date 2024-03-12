variable "resource_group_name" {
  description = "The name of the resource group in which to create the resource. Changing this forces a new resource to be created"
  type        = string
  default     = ""
}

variable "project_name" {
  description = "The name of the project e.g. ccv/hgv. Changing this forces a new resource to be created."
  type        = string
}

variable "environment" {
  type        = string
  description = "environment name"
}

variable "namespace_sku" {
  description = "Defines which tier to use - options are Basic, Standard or Premium."
  type        = string
  default     = "Basic"
  validation {
    condition     = can(regex("Basic|Standard|Premium", var.namespace_sku))
    error_message = "Servicebus sku can only be Basic, Standard or Premium."
  }
}

variable "namespace_capacity" {
  description = "Specifies the capacity. When sku is Premium, capacity can be 1, 2, 4 or 8. When sku is Basic or Standard, capacity can be 0 only"
  type        = number
  default     = 0
}

variable "namespace_zone_redundancy" {
  description = "Whether or not this resource is zone redundant. sku needs to be Premium. Defaults to true."
  default     = true
}

variable "tags" {
  description = "A mapping of tags to assign to the resource"
  type        = map(string)
  default     = {}
}

variable "queues" {
  description = "map of queues to create"
  default     = {}
}

variable "topics" {
  description = "map of topics to create"
  default     = {}
}

variable "subscriptions" {
  description = "map of subscriptions to create"
  default     = {}
}

variable "subscription_rules" {
  description = "map of subscription rules to create"
  default     = {}
}

variable "authorization_rules" {
  description = "map of authorization rules to create"
  default     = {}
}

variable "network_rules" {
  description = "map of authorization rules to create"
  default     = {}
}
