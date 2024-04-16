#get the existing vNet
data "azurerm_virtual_network" "vnet" {
  name                 = local.existingVnetName
  resource_group_name  = local.existingVnetresource_group_name
}

#get the existing subnets
data "azurerm_subnet" "vmsubnet" {
  name                 = local.vmSubnetName
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_virtual_network.vnet.resource_group_name
}

locals {
  resource_group_name   = "${var.resource_group_name}" 
  location              = "${var.location}"
  #keyvault_name        = lower("kv-${var.environment}-${var.unique_id}")
  vm_name               = "${var.prefix}-vm-${var.projectName}-${var.environment}-${var.location}"
  vm_pubip_name         = "${var.prefix}-pubip-${var.projectName}-${var.environment}-${var.location}"
  nsg_name              = "${var.prefix}-nsg-${var.projectName}-${var.environment}-${var.location}"
  nic_name              = "${var.prefix}-nic-${var.projectName}-${var.environment}-${var.location}"
  os_disk_name          = "${var.prefix}-osdisk-${var.projectName}-${var.environment}-${var.location}"
  nic_config_name       = "${var.prefix}-nic_configuration"
  storage_account_name  = "${var.prefix}store${var.projectName}vm"
  vmSubnetName         = "${var.subnet_name}"
  existingVnetName      = "${var.vnet_name}"
  existingVnetresource_group_name  = "${var.vnet_resource_group_name}"  
  vm_size               = "${var.vm_size}"
  vm_image_publisher    = "${var.vm_image_publisher}"
  vm_image_offer    	  = "${var.vm_image_offer}"
  vm_image_sku          = "${var.vm_image_sku}"
  vm_image_version      = "${var.vm_image_version}"
  vm_admin_user_name    = "${var.vm_admin_user_name}"
  vm_admin_user_password    = "${var.vm_admin_user_password}"
  ssh_public_key        = "${var.ssh_public_key}"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "my_terraform_nsg" {
  name                = local.nsg_name
  location            = local.location
  resource_group_name = local.resource_group_name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "my_terraform_nic" {
  name                = local.nic_name
  location            = local.location
  resource_group_name = local.resource_group_name

  ip_configuration {
    name                          = local.nic_config_name
    subnet_id                     = data.azurerm_subnet.vmsubnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.my_terraform_nic.id
  network_security_group_id = azurerm_network_security_group.my_terraform_nsg.id
}

# Generate random text for a unique storage account name
resource "random_id" "random_id" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = local.resource_group_name
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "my_storage_account" {
  name                     = local.storage_account_name
  location                 = local.location
  resource_group_name      = local.resource_group_name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
}

# Create (and display) an SSH key
resource "tls_private_key" "example_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "my_terraform_vm" {
  name                  = local.vm_name
  location              = local.location
  resource_group_name   = local.resource_group_name
  network_interface_ids = [azurerm_network_interface.my_terraform_nic.id]
  size                  = local.vm_size

  os_disk {
    name                 = local.os_disk_name
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = local.vm_image_publisher
    offer     = local.vm_image_offer
    sku       = local.vm_image_sku
    version   = local.vm_image_version
  }

  computer_name                   = local.vm_name
  admin_username                  = local.vm_admin_user_name
  admin_password                  = local.vm_admin_user_password
  disable_password_authentication = false

  admin_ssh_key {
    username   = local.vm_admin_user_name
    #public_key = tls_private_key.example_ssh.public_key_openssh
    public_key = local.ssh_public_key
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.my_storage_account.primary_blob_endpoint
  }
}

#Ref https://learn.microsoft.com/en-us/azure/virtual-machines/linux/quick-create-terraform