terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "sttfstate82293"
    container_name       = "tfstate"
    key                  = "azure-cloud-lab.tfstate"
  }
}