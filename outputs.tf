output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "web_vm_public_ip" {
  value = azurerm_public_ip.web_pip.ip_address
}

output "web_vm_private_ip" {
  value = azurerm_network_interface.web_nic.private_ip_address
}

output "db_vm_private_ip" {
  value = azurerm_network_interface.db_nic.private_ip_address
}

output "storage_account_name" {
  value = azurerm_storage_account.storage.name
}