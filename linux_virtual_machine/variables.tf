variable "create_resource_group" {
  description = "Whether to create resource group and use it for all networking resources"
  default     = true
}

variable "resource_group_name" {
  description = "A container that holds related resources for an Azure solution"
  default     = "rg-miles-mmp-tools-sit-uksouth"
}

variable "location" {
  description = "The location/region to keep all your network resources. To get the list of all locations with table format from azure cli, run 'az account list-locations -o table'"
  default     = "uksouth"
}

variable "projectName" {
  description = "Name to be used for the project to tag all the resources"
  default     = "mmp"
}

variable "environment"{
  description = "The name for the environment"
  default     = "sit"
}

variable "prefix" {
    type = string
    default = "jmp"
}

variable "tags" {
    type = map(string)

    default = {
    source = "terraform"
    }
}

variable "vnet_name" {
  description = "Name of the vnet to associate."
  type        = string
  default     = "vnet-mmp-spoke-sit-uksouth"
}

variable "subnet_name" {
  description = "Name of the subnet to associate."
  type        = string
  default     = "snet-vms-mmp-sit-uksouth"
}

variable "vnet_resource_group_name" {
  description = "Name of the resource group hosting the vnet."
  type        = string
  default     = "rg-miles-mmp-vnet-uksouth"
}

variable "vm_size" {
  description = "Size of the VM to be provisioned."
  type        = string
  default     = "Standard_DS1_v2"
}

variable "vm_image_publisher" {
  description = "Size of the VM to be provisioned."
  type        = string
  default     = "Canonical"
}

variable "vm_image_offer" {
  description = "Size of the VM to be provisioned."
  type        = string
  default     = "UbuntuServer"
}

variable "vm_image_sku" {
  description = "Size of the VM to be provisioned."
  type        = string
  default     = "18.04-LTS"
}

variable "vm_image_version" {
  description = "Size of the VM to be provisioned."
  type        = string
  default     = "latest"
}

variable "vm_admin_user_name" {
  description = "Admin user name for the VM to be provisioned."
  type        = string
  default     = "azureuser"
}

variable "vm_admin_user_password" {
  description = "Admin user password for the VM to be provisioned."
  type        = string
  default     = "th15ismyp@55w0rd"
}

variable "ssh_public_key" {
  description = "custom ssh public key generated for the VM access management."
  type        = string
  default     = "azureuser"
  sensitive = true
}