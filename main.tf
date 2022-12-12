
#azurerm_resource_group
resource "azurerm_resource_group" "neciprg" {
  name     = var.resource_name
  location = var.location
}
#azurerm_storage_account
resource "azurerm_storage_account" "necipstg" {
  name                     = var.azurerm_storage_account
  resource_group_name      = azurerm_resource_group.neciprg.name
  location                 = azurerm_resource_group.neciprg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = {
    environment = "staging"
  }
}
#azurerm_virtual_network
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.vm_name}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.neciprg.location
  resource_group_name = azurerm_resource_group.neciprg.name
}
#azurerm_subnet
resource "azurerm_subnet" "subnet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.neciprg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}
#azurerm_network_interface
resource "azurerm_network_interface" "nic" {
  name                = "${var.vm_name}-nic"
  location            = azurerm_resource_group.neciprg.location
  resource_group_name = azurerm_resource_group.neciprg.name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}
#azurerm_virtual_machine
resource "azurerm_virtual_machine" "vm" {
  name                  = "${var.vm_name}-vm"
  location              = azurerm_resource_group.neciprg.location
  resource_group_name   = azurerm_resource_group.neciprg.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  vm_size               = "Standard_DS1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = var.vm_name
    admin_username = var.user_name
    admin_password = var.user_password
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }
}