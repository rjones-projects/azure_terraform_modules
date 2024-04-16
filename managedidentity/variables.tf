variable "projectName" {
  description = "Name of the project acssociated with this Id"
  default     = ""
}

variable "resource_group_name" {
  description = "A container that holds related resources for an Azure solution"
  default     = ""
}

variable "location" {
  description = "location of the Id"
  default     = ""
}

variable "environment"{
  description = "The name for the environment"
  default     = ""
}

variable "uniqueSuffix"{
  description = "unique string to suffix the resource"
  default     = "Pass-Unique-String-Please"
}

variable "tags" {
  default = { }
}