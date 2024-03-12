variable "name" {
  description = "The name of the application."
  type        = string
}

variable "environment" {
  description = "The environment being deployed to."
  type        = string
}

variable "project_name" {
  description = "The name of the project e.g. ccv/hgv. Changing this forces a new resource to be created."
  type        = string
}

variable "app_service_plan_properties" {
  description = "Function App Service Plan properties, to create a plan if not using an existing plan."

  type = map(object({
    sku_name                     = string
    maximum_elastic_worker_count = optional(number)
    worker_count                 = number
    per_site_scaling_enabled     = bool
    zone_balancing_enabled       = bool
  }))

  default = {}
}

variable "app_service_plan_name" {
  description = "Name of the App Service Plan for Function App hosting, if using an existing service plan. Ignored if app_service_plan_properties is set."
  type        = string
  default     = ""
}

variable "application_insights_instrumentation_key" {
  description = "Application Insights instrumentation key for function logs, if using an existing application_insights instance."
  type        = string
  default     = ""
}

variable "function_app_properties" {
  description = "Function App properties."

  type = map(object({
    application_settings = optional(map(any), {})
    site_config = object({
      always_on                   = bool
      ftps_state                  = string
      use_32_bit_worker           = bool
      scm_use_main_ip_restriction = bool
      health_check_path           = string
    })
    cors = object({
      allowed_origins     = list(string)
      support_credentials = bool
    })
    identity = object({
      type = string
    })
    subnet_name              = string
    vnet_name                = string
    vnet_resource_group_name = string
  }))
}

variable "resource_group_name" {
  description = "Resource group name."
  type        = string
}

variable "storage_account_name" {
  description = "Storage account name, if using an existing storage account."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to use."
  type        = map(any)
}
