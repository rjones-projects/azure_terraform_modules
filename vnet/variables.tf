variable "create_resource_group" {
  description = "Whether to create resource group and use it for all networking resources"
  default     = false
}

variable "resource_group_name" {
  description = "A container that holds related resources for an Azure solution"
  default     = "rg-demo-westeurope-01"
}

variable "location" {
  description = "The location/region to keep all your network resources. To get the list of all locations with table format from azure cli, run 'az account list-locations -o table'"
  default     = "westeurope"
}

variable "vnetwork_name" {
  description = "Name of your Azure Virtual Network"
  default     = "vnet-azure-westeurope-001"
}

variable "vnet_address_space" {
  description = "The address space to be used for the Azure virtual network."
  default     = ["10.0.0.0/16"]
}

variable "create_ddos_plan" {
  description = "Create an ddos plan - Default is false"
  default     = false
}

variable "dns_servers" {
  description = "List of dns servers to use for virtual network"
  default     = ["172.17.3.4", "172.17.3.5"]
}

variable "ddos_plan_name" {
  description = "The name of AzureNetwork DDoS Protection Plan"
  default     = "azureddosplan01"
}

variable "create_network_watcher" {
  description = "Controls if Network Watcher resources should be created for the Azure subscription"
  default     = true
}
variable "subnet_delegations_actions" { #needed as there is a bug in the provider which toggles actions in some cases (e.g. Microsoft.Sql/managedInstances)
  type = map(list(string))
  default = {
    "Microsoft.Web/serverFarms"                       = ["Microsoft.Network/virtualNetworks/subnets/action"]
    "Microsoft.ContainerInstance/containerGroups"     = ["Microsoft.Network/virtualNetworks/subnets/action"]
    "Microsoft.Netapp/volumes"                        = ["Microsoft.Network/networkinterfaces/*", "Microsoft.Network/virtualNetworks/subnets/join/action"]
    "Microsoft.HardwareSecurityModules/dedicatedHSMs" = ["Microsoft.Network/networkinterfaces/*", "Microsoft.Network/virtualNetworks/subnets/join/action"]
    "Microsoft.ServiceFabricMesh/networks"            = ["Microsoft.Network/virtualNetworks/subnets/action"]
    "Microsoft.Logic/integrationServiceEnvironments"  = ["Microsoft.Network/virtualNetworks/subnets/action"]
    "Microsoft.Batch/batchAccounts"                   = ["Microsoft.Network/virtualNetworks/subnets/action"]
    "Microsoft.Sql/managedInstances"                  = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action", "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"]
    "Microsoft.Web/hostingEnvironments"               = ["Microsoft.Network/virtualNetworks/subnets/action"]
    "Microsoft.BareMetal/CrayServers"                 = ["Microsoft.Network/networkinterfaces/*", "Microsoft.Network/virtualNetworks/subnets/join/action"]
    "Microsoft.Databricks/workspaces"                 = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action", "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"]
    "Microsoft.BareMetal/AzureVMware"                 = ["Microsoft.Network/networkinterfaces/*", "Microsoft.Network/virtualNetworks/subnets/join/action"]
    "Microsoft.StreamAnalytics/streamingJobs"         = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    "Microsoft.DBforPostgreSQL/serversv2"             = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    "Microsoft.AzureCosmosDB/clusters"                = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    "Microsoft.ContainerService/managedClusters"      = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action", "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"]
  }
}
variable "subnets" {
  description = "For each subnet, create an object that describes the subnet"
  type = map(object({
    name = string,
    subnet_address_prefix                         = string,
    service_endpoints                             = optional(list(string), null),
    private_endpoint_network_policies_enabled     = optional(bool, true),
    private_link_service_network_policies_enabled = optional(bool, false),
    delegation = optional(object({
      name = optional(string),
      service_delegation = optional(object({
        name = optional(string),
        # actions = optional(list(string)),
      }), {})
    }), null),
    nsg_inbound_rules = optional(map(object({
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
    })), {}),
    nsg_outbound_rules = optional(map(object({
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
    })), {}),
  }))
}

variable "gateway_subnet_address_prefix" {
  description = "The address prefix to use for the gateway subnet"
  default     = null
}

variable "firewall_private_ip_address" {
  description = "The ip address to use for the Firewall"
  default     = "172.19.1.68"
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
