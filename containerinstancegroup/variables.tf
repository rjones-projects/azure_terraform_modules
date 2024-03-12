variable "create_resource_group" {
  description = "Whether to create resource group and use it for all networking resources"
  default     = false
}

variable "resource_group_name" {
  description = "A container that holds related resources for an Azure solution"
  default     = ""
}

variable "location" {
  description = "The location/region to keep all your network resources. To get the list of all locations with table format from azure cli, run 'az account list-locations -o table'"
  default     = "uksouth"
}

variable "environment"{
  description = "The name for the environment"
  default     = "dev"
}

variable "subnet_id" {
  description = "The resource id of the subnet for vnet association"
  default     = null
}
variable "port" {
  description = "The port to use for this ACI"
  default     = null
}

variable "protocol" {
  description = "The protocol to use for this ACI"
  default     = "TCP"
}

variable "cpu" {
  description = "The CPU to use for this ACI"
  default     = 1
}

variable "memory" {
  description = "The RAM to use for this ACI"
  default     = 4
}

variable "project_name" {
  description = "Specifies the name of the project"
  default     = ""
}

variable "image_name" {
  description = "Specifies the name of the docker image"
  default     = ""
}

variable "dns_name" {
  description = "Specifies the dns name of the ACI"
  default     = ""
}

variable "registry_username" {
  description = "Specifies the user name for the registry holding the docker image"
  default     = "zvcenterprise"
}
variable "registry_pass" {
  description = "Specifies the password for the registry holding the docker image"
  default     = "KktvwYetrUDgD7bA=+oslMuK=fVnprUp"
}
variable "registry_url" {
  description = "Specifies the registry holding the docker image"
  default     = "zvcenterprise.azurecr.io"
}

variable "env_variables" {
  description = "A map of environment variables to apply to the ACI"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}