#generate a random string for appending to resources
resource "random_string" "id" {
   length = 5
   special = false
   upper = false
 }

locals {
  #translate the set of disk objects into a set of strings that can be used by for-each
  vm_data_disks = { for idx, data_disk in var.managedDataDisks : data_disk.id => {
    idx : idx,
    data_disk : data_disk,
    }
  }
}

# resource "azurerm_public_ip" "pip" {
#  count    = var.createPublicIpAddress ? 1 : 0
#  name                          = "${var.serverName}-publicip-${random_string.id.result}"
#  location                      = "${var.resourceGroup.location}"
#  resource_group_name           = "${var.resourceGroup.name}"
#  domain_name_label             = var.domainNameLabel
#  allocation_method             = "Static"
# }

resource "azurerm_network_interface" "nic" {
  name                                  = "${var.serverName}-nic-${random_string.id.result}"
  location                              = "${var.resourceGroup.location}"
  resource_group_name                   = "${var.resourceGroup.name}"

  enable_accelerated_networking       = true
  
  ip_configuration {
    name                            = "${var.serverName}-nic-ip-config-${random_string.id.result}"
    subnet_id                       = "${var.subnet.id}"
    private_ip_address_allocation   = "Static"
    private_ip_address              = "${var.privateIpAddress}"
    #count    = var.createPublicIpAddress ? 1 : 0
    #public_ip_address_id            = "${azurerm_public_ip.pip[0].id}"
  }

  tags = var.tags
}

resource "azurerm_windows_virtual_machine" "vm" {
  name                  = "${var.serverName}"
  location              = "${var.resourceGroup.location}"
  resource_group_name   = "${var.resourceGroup.name}"
  network_interface_ids = [azurerm_network_interface.nic.id]
  size                  = "${var.vmSize}"
  admin_username        = var.vmAdminUserName
  admin_password        = var.vmAdminUserPass

  source_image_reference {
    publisher = "${var.publisher}"
    offer     = "${var.offer}"
    sku       = "${var.sku}"
    version   = "${var.imageVersion}"
  }

  os_disk {
    name                = "${var.serverName}-OS-Disk"
    caching             = "ReadWrite"
    storage_account_type   = "Standard_LRS"
  }

  tags = var.tags
  depends_on = [azurerm_network_interface.nic]
}

 # Optional data disks
resource "azurerm_managed_disk" "data" {
  for_each             = local.vm_data_disks
  name                 = "${var.serverName}-DataDisk-${each.value.idx}"
  resource_group_name  = "${var.resourceGroup.name}"
  location             = "${var.resourceGroup.location}"
  storage_account_type = lookup(each.value.data_disk, "storage_account_type", "StandardSSD_LRS")
  create_option        = "Empty"
  disk_size_gb         = each.value.data_disk.disk_size_gb
  tags                 = merge({ "ResourceName" = "${var.serverName}-DataDisk-${each.value.idx}" }, var.tags, )

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "data" {
  for_each           = local.vm_data_disks
  managed_disk_id    = azurerm_managed_disk.data[each.key].id
  virtual_machine_id = azurerm_windows_virtual_machine.vm.id
  lun                = each.value.idx
  caching            = "ReadWrite"
}