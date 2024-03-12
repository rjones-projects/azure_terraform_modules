variable "name" {
  description = "Name of the MySQL Server"
  default     = ""
}
variable "location" {
  description = "location of the MySQL Server"
  default     = ""
}
variable "resourceGroup" {
  description = "resourceGroup of the MySQL Server"
  default     = ""
}
variable "Sku" {
  description = "SKU of the MySQL Server"
  default     = ""
}
variable "storage_mb" {
  description = "Storage allocated forthe MySQL Server"
  default     = ""
}

variable "administrator_login" {
  description = "admin account the MySQL Server"
  default     = ""
}
variable "administrator_login_password" {
  description = "admin account password for the MySQL Server"
  default     = ""
}
variable "ssl_enforcement_enabled" {
  description = "SSL for the MySQL Server"
  default     = ""
}
variable "ssl_minimal_tls_version_enforced" {
  description = "Min TLS level for the MySQL Server"
  default     = ""
}

variable "tags" {
  type = map
  default = {
  }

}