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
  default     = ""
}

variable "tags" {
  default = { }
}