variable "create_resource_group" {
  description = "Whether to create resource group and use it for all networking resources"
  default     = false
}

variable "resource_group_name" {
  description = "A container that holds related resources for an Azure solution"
  default     = ""
}

variable "projectName" {
  description = "Name of the project acssociated with this RG"
  default     = ""
}

variable "location" {
  description = "location of the RG"
  default     = ""
}

variable "environment"{
  description = "The name for the environment"
  default     = "dev"
}

variable "subnet_id" {
  description = "The Id of the subnet where the Sql Managed Instance should exist"
  type        = string
  default     = null
}

variable "vcores" {
  description = "Number of vCores in the instance"
  type        = number
  default     = 4
}

variable "admin_username" {
  description = "The administrator login name for the new SQL Server"
  default     = null
}

variable "admin_password" {
  description = "The password associated with the admin_username user"
  default     = null
}


variable "storage_size_in_gb" {
  description = "storage allocated"
  type        = number
  default     = 32
}

variable "tags" {
  default = { }
}