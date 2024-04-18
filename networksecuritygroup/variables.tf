variable "virtual_network_name" {
  description = "virtual_network_name to attach the nsg"
  type = string
  default = null
}

variable "subnet_name" {
  description = "subnet to attach the nsg"
  type = string
  default = null
}

variable "resource_group_name" {
  description = "resource_group of the nsg"
  default     = ""
}

variable "nsg_inbound_rules" {
  description = "inbound rules for the NSG"
  type = map(object({
      # name                       = string,
      priority                   = number,
      direction                  = optional(string, "Inbound"),      
      access                     = optional(string, "Allow"),
      protocol                   = optional(string, "Tcp"),
      source_port_range          = optional(string, "*"),
      destination_port_range     = optional(string, "*"),
      source_address_prefix      = optional(string, "*"),
      destination_address_prefix = optional(string, "*"),
      description                = optional(string, null),      
    }))
  default     = {}
}
variable "nsg_outbound_rules" {
  description = "inbound rules for the NSG"
  type = map(object({
      # name                       = string,
      priority                   = number,
      direction                  = optional(string, "Outbound"),      
      access                     = optional(string, "Allow"),
      protocol                   = optional(string, "Tcp"),
      source_port_range          = optional(string, "*"),
      destination_port_range     = optional(string, "*"),
      source_address_prefix      = optional(string, "*"),
      destination_address_prefix = optional(string, "*"),
      description                = optional(string, null),      
    }))
  default     = {}
}
variable "tags" {
  default = {
    environment = "development"
  }
}