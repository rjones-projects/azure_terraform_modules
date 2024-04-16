variable "serverName" {
  description = "Name of the VM"
  default     = ""
}

variable "resource_group" {
  description = "resource_group of the Server"
  default     = ""
}

variable "vmSize" {
  description = "vmSize of the Server"
  default     = "Standard_B2s"
}

variable "privateIpAddress" {
  description = "Private IP# of the Server"
  default     = ""
}

variable "createPublicIpAddress" {
  description = "create a Public IP# for the Server"
  default     = false
}

variable "domainNameLabel" {
    description = "DNS name"
    default = null
}

variable "publisher" {
  description = "Image publisher"
  default     = "MicrosoftWindowsServer"
}

variable "offer" {
  description = "Image Offer"
  default     = "WindowsServer"
}

variable "sku" {
  description = "Image SKU"
  default     = "2019-Datacenter"
}

variable "imageVersion" {
  description = "Image version"
  default     = "latest"
}

variable managedDataDisks{
  description = "Managed Disks to attach to VM"
  type = list(object({
    id                   = number
    storage_account_type = string
    disk_size_gb         = number
  }))
  default = []
}

variable "subnet" {
  description = "subnet to attach the Server"
}

variable "nsg" {
  description = "Nsg controlling access to the Server"
  default = null
}

variable "tags" {
  default = {
    environment = "development"
  }
}

variable "vmAdminUserName" {
    description = "Local Admin user"
    default = "ZenAdmin"
}

variable "vmAdminUserPass" {
    description = "Local Admin Pass"
    default = ""
}