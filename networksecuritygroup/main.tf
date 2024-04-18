locals{
  nsg_name = var.subnet_name != null ? "nsg-${var.subnet_name}" : "nsg-"
}
#get the subnet
data "azurerm_subnet" "snet" {
  name = var.subnet_name
  virtual_network_name = var.virtual_network_name
  resource_group_name  = var.resource_group_name  
}
#Get the RG
data "azurerm_resource_group" "nsg" {
  name = var.resource_group_name
}

#create the NSG
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-${var.subnet.name}"
  location            = var.resource_group.location
  resource_group_name = var.resource_group_name
  tags = var.tags
}

#link the NSG to the subnet if provided
resource "azurerm_subnet_network_security_group_association" "nsg" {
  count = var.subnet.id != null ? 1 : 0
  subnet_id                 = var.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

#Add the rules for the NSG
resource "azurerm_network_security_rule" "nsgrules" {
    for_each                      =  merge(each.value.nsg_inbound_rules,each.value.nsg_outbound_rules)
    name                          = "snet-${each.key}-${var.resource_group.location}"
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
    description                   = lookup(each.value, "description", "Destination_Port: ${each.value.destination_port_range}_${each.value.direction}")

}
