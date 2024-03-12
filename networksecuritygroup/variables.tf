variable "subnet" {
  description = "subnet to attach the Server"
}

variable "resourceGroup" {
  description = "resourceGroup of the Server"
  default     = ""
}

variable "nsgRules" {
  description = "rules for the NSG"
  default     = []
}

variable "tags" {
  default = {
    environment = "development"
  }
}