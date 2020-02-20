resource "azurerm_resource_group" "web" {
  name     = "module-resources"
  count = var.instance_count
  location = "West US 2"
}

resource "azurerm_virtual_network" "web" {
  name                = "module-network"
  count = var.instance_count
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.web[0].location
  resource_group_name = azurerm_resource_group.web[0].name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  count = var.instance_count
  resource_group_name  = azurerm_resource_group.web[0].name
  virtual_network_name = azurerm_virtual_network.web[0].name
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_network_interface" "web" {
  name                = "module-nic"
  count = var.instance_count
  location            = azurerm_resource_group.web[0].location
  resource_group_name = azurerm_resource_group.web[0].name

  ip_configuration {
    name                          = "snowconfig"
    subnet_id                     = azurerm_subnet.internal[0].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "main" {
  name                  = "module-vm"
  location              = azurerm_resource_group.web[0].location
  resource_group_name   = azurerm_resource_group.web[0].name
  network_interface_ids = [azurerm_network_interface.web[0].id]
  vm_size               = var.instance_type

  count = var.instance_count
  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

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
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }

}
