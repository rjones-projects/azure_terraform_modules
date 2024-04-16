variable "subnet_id" {
  type = optional(string,null)
  description = "subnet to attach the nsg"
}

variable "resource_group_name" {
  description = "resource_group of the nsg"
  default     = ""
}

variable "nsg_inbound_rules" {
  description = "inbound rules for the NSG"
  default     = []
}
variable "nsg_outbound_rules" {
  description = "inbound rules for the NSG"
  default     = []
}
variable "tags" {
  default = {
    environment = "development"
  }
}