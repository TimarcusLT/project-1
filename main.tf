# Resource Group
resource "azurerm_resource_group" "RG1" {
  name     = "${var.RGname}"
  location = "${var.location}"
  tags     = {
     source = "terraform" 
  }
}

# Azure Users
resource "azuread_user" "trainee" {
  user_principal_name = "${var.traineeUP}"
  display_name        = "${var.traineeDN}"
  depends_on = [azurerm_resource_group.RG1]
}
resource "azuread_user" "trainer" {
  user_principal_name = "${var.trainerUP}"
  display_name        = "${var.trainerDN}"
  force_password_change = "true"
  depends_on = [azuread_user.trainee] 
}
# S3 Buckets
resource "aws_s3_bucket" "bucket" {
    bucket = "${var.s3BN}-${count.index}"
    count  = var.BucNum
   depends_on = [azuread_user.trainer]
}
# AWS Users
resource "aws_iam_user" "NU" {
    for_each = toset(var.users)
    name     = each.value
    depends_on = [aws_s3_bucket.bucket]
}
# Azure Storage Account
resource "azurerm_storage_account" "stg-acc" {
  name                 = "${var.SAN}"
  resource_group_name  = azurerm_resource_group.RG1.name
  location             = azurerm_resource_group.RG1.location
  account_tier         = "${var.SAT}"
  account_replication_type = "${var.SART}"
  tags = {
    department = "storage"
  }
  
  depends_on = [aws_iam_user.NU]
}
# Azure Virtual Machine
resource "azurerm_virtual_machine" "main" {
  name                  = "${var.VMN}"
  location              = azurerm_resource_group.RG1.location
  resource_group_name   = azurerm_resource_group.RG1.name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = "Standard_DS1_v2"

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
    environment = "Virtual Machine"
  }
}
