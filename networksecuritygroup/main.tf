#create the NSG
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.subnet.name}-NSG"
  location            = var.resourceGroup.location
  resource_group_name = var.resourceGroup.name
  tags = var.tags
}

#link the NSG to the subnet
resource "azurerm_subnet_network_security_group_association" "nsg" {
  subnet_id                 = var.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

#Add the rules for the NSG
resource "azurerm_network_security_rule" "nsgrules" {
    for_each                      = var.nsgRules 
    name                          = each.key
    direction                     = each.value.direction
    access                        = each.value.access
    priority                      = each.value.priority
    protocol                      = each.value.protocol
    source_port_range             = each.value.source_port_range
    destination_port_range        = each.value.destination_port_range
    source_address_prefix         = each.value.source_address_prefix
    destination_address_prefix    = each.value.destination_address_prefix
    resource_group_name           = azurerm_network_security_group.nsg.resource_group_name
    network_security_group_name   = azurerm_network_security_group.nsg.name
}
