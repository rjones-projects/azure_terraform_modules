
resource "azurerm_user_assigned_identity" "Identity" {

    name = "id-${var.projectName}-${var.environment}-${var.location}-${var.uniqueSuffix}"
    resource_group_name = var.resourceGroupName
    location            = var.location
    tags = var.tags
}