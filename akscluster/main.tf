data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

#generate a random string for appending to kubelet_id
resource "random_string" "kubeletid" {
   length = 5
   special = false
   upper = false
 }

#----------------------------------------------
#Create the User Assigned Identity which will be used as the kubelet identity
#----------------------------------------------
module "kubeletIdentity"{
  source    = "../managedidentity"
  projectName     = var.cluster_name
  resource_group_name  =  var.resource_group_name
  location        = var.location
  environment     = var.environment
  uniqueSuffix    = "kubelet-${random_string.kubeletid.result}"
  tags            = var.tags
}

resource "azurerm_role_assignment" "kubelet-reader-role-rg" {
  scope                = data.azurerm_resource_group.main.id
  role_definition_name = "Reader"
  principal_id         = module.kubeletIdentity.principal_id
}

resource "azurerm_role_assignment" "kubelet-identity-operator-role-rg" {
  scope                = data.azurerm_resource_group.main.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = module.kubeletIdentity.principal_id
}

resource "azurerm_role_assignment" "aks-kubelet-identity-operator-role" {
  scope                = module.kubeletIdentity.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = module.kubeletIdentity.principal_id
}

resource "azurerm_role_assignment" "aks-kubelet-rg-contributer-role" {
  scope                = data.azurerm_resource_group.main.id
  role_definition_name = "Contributor"
  principal_id         = module.kubeletIdentity.principal_id
}

resource "azurerm_role_assignment" "aks-kubelet-rg-networkcontributer-role" {
  scope                = data.azurerm_resource_group.main.id
  role_definition_name = "Network Contributor"
  principal_id         = module.kubeletIdentity.principal_id
}

resource "azurerm_role_assignment" "kubelet-private-dns-contributor-role" {
  scope                = var.private_dns_zone_id
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = module.kubeletIdentity.principal_id
}


#add roles to access the node rg
data "azurerm_resource_group" "node" {
  name = azurerm_kubernetes_cluster.main.node_resource_group
  depends_on = [resource.azurerm_kubernetes_cluster.main]
}

resource "azurerm_role_assignment" "aks-kubelet-noderg-contributor-role" {
  scope                = data.azurerm_resource_group.node.id
  role_definition_name = "Contributor"
  principal_id         = module.kubeletIdentity.principal_id
  depends_on = [data.azurerm_resource_group.node]
}

resource "azurerm_role_assignment" "aks-kubelet-noderg-identity-operator-role" {
  scope                = data.azurerm_resource_group.node.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = module.kubeletIdentity.principal_id
  depends_on = [data.azurerm_resource_group.node]
}

# data "azurerm_subscription" "primary" {}

# resource "azurerm_role_assignment" "kubelet-identity-operator-role-aks-rg" {
#   scope                = data.azurerm_subscription.primary.id
#   role_definition_name = "Managed Identity Operator"
#   principal_id         = module.kubeletIdentity.principal_id
#   depends_on           = [resource.azurerm_kubernetes_cluster.main]
# }

#----------------------------------------------
#Create the AKS Cluster
#----------------------------------------------
resource "azurerm_kubernetes_cluster" "main" {
  name                    = var.cluster_name == null ? "${var.prefix}-aks" : var.cluster_name
  kubernetes_version      = var.kubernetes_version
  location                = coalesce(var.location, data.azurerm_resource_group.main.location)
  resource_group_name     = data.azurerm_resource_group.main.name
  node_resource_group     = var.node_resource_group_name
  dns_prefix              = var.prefix
  sku_tier                = var.sku_tier
  private_cluster_enabled = var.private_cluster_enabled
  private_dns_zone_id     = var.private_dns_zone_id
  local_account_disabled  = var.local_account_disabled

  # linux_profile {
  #   admin_username = var.admin_username
  #   ssh_key {
  #       # remove any new lines using the replace interpolation function
  #       key_data = replace(coalesce(var.public_ssh_key, tls_private_key.ssh.public_key_openssh), "\n", "")
  #   }
  # }

  default_node_pool {
      orchestrator_version         = var.orchestrator_version
      name                         = var.agents_pool_name
      vm_size                      = var.agents_size
      os_disk_size_gb              = var.os_disk_size_gb
      os_disk_type                 = var.os_disk_type
      vnet_subnet_id               = var.node_subnet_id
      pod_subnet_id                = var.pod_subnet_id
      enable_auto_scaling          = var.enable_auto_scaling
      max_count                    = var.agents_max_count
      min_count                    = var.agents_min_count
      enable_node_public_ip        = var.enable_node_public_ip
      zones                        = var.agents_availability_zones
      node_labels                  = var.agents_labels
      type                         = var.agents_type
      tags                         = merge(var.tags, var.agents_tags)
      max_pods                     = var.agents_max_pods
      enable_host_encryption       = var.enable_host_encryption
      only_critical_addons_enabled = var.only_critical_addons_enabled
  }

  identity {
    type = "UserAssigned"
    identity_ids = var.identity_ids
  }

  kubelet_identity {
      client_id = module.kubeletIdentity.client_id
      object_id = module.kubeletIdentity.id
      user_assigned_identity_id = module.kubeletIdentity.id
  }

  http_application_routing_enabled = var.enable_http_application_routing

  azure_policy_enabled = var.azure_policy_enabled

  oms_agent {
      log_analytics_workspace_id = azurerm_log_analytics_workspace.main[0].id 
  }

  open_service_mesh_enabled = var.enable_open_service_mesh

  ingress_application_gateway {
      gateway_id   = var.ingress_application_gateway_id
      gateway_name = var.ingress_application_gateway_name
      subnet_cidr  = var.ingress_application_gateway_subnet_cidr
      subnet_id    = var.ingress_application_gateway_subnet_id
  }

  key_vault_secrets_provider {
      secret_rotation_enabled  = var.secret_rotation_enabled
      secret_rotation_interval = var.secret_rotation_interval
  }

  role_based_access_control_enabled = true

  azure_active_directory_role_based_access_control {
      managed                = true
      admin_group_object_ids = var.rbac_aad_admin_group_object_ids
      azure_rbac_enabled     = var.rbac_aad_azure_rbac_enabled
      tenant_id              = var.rbac_aad_tenant_id
  }

  network_profile {
    network_plugin     = var.network_plugin
    network_policy     = var.network_policy
    dns_service_ip     = var.net_profile_dns_service_ip
    docker_bridge_cidr = var.net_profile_docker_bridge_cidr
    outbound_type      = var.net_profile_outbound_type
    pod_cidr           = var.net_profile_pod_cidr
    service_cidr       = var.net_profile_service_cidr
  }

  oidc_issuer_enabled = var.oidc_issuer_enabled

  tags = var.tags
  depends_on = [azurerm_role_assignment.kubelet-private-dns-contributor-role]
}

resource "azurerm_log_analytics_workspace" "main" {
  count               = var.enable_log_analytics_workspace && var.log_analytics_workspace == null ? 1 : 0
  name                = var.cluster_log_analytics_workspace_name == null ? "${var.prefix}-workspace" : var.cluster_log_analytics_workspace_name
  location            = coalesce(var.location, data.azurerm_resource_group.main.location)
  resource_group_name = coalesce(var.log_analytics_workspace_resource_group_name, var.resource_group_name)
  sku                 = var.log_analytics_workspace_sku
  retention_in_days   = var.log_retention_in_days

  tags = var.tags
}

resource "azurerm_log_analytics_solution" "main" {
  count                 = var.enable_log_analytics_workspace && var.log_analytics_solution_id == null ? 1 : 0
  solution_name         = "ContainerInsights"
  location              = coalesce(var.location, data.azurerm_resource_group.main.location)
  resource_group_name   = coalesce(var.log_analytics_workspace_resource_group_name, var.resource_group_name)
  workspace_resource_id = var.log_analytics_workspace != null ? var.log_analytics_workspace.id : azurerm_log_analytics_workspace.main[0].id
  workspace_name        = var.log_analytics_workspace != null ? var.log_analytics_workspace.name : azurerm_log_analytics_workspace.main[0].name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }

  tags = var.tags
}

resource "azurerm_kubernetes_cluster_node_pool" "aks" {

  for_each = var.additional_node_pools

  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vnet_subnet_id        = var.node_subnet_id
  pod_subnet_id         = var.pod_subnet_id  
  name                  = substr(each.key, 0, 12)
  vm_size               = each.value.vm_size
  os_disk_size_gb       = each.value.os_disk_size_gb
  enable_auto_scaling   = each.value.enable_auto_scaling
  zones                 = each.value.zones
  node_count            = each.value.node_count
  min_count             = each.value.min_count
  max_count             = each.value.max_count
  max_pods              = each.value.max_pods
  node_labels           = each.value.node_labels
  node_taints           = each.value.taints
}