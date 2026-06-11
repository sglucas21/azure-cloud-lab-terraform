variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
  default     = "rg-cloud-lab-terraform"
}

variable "admin_username" {
  description = "Windows VM admin username"
  type        = string
  default     = "azureadmin"
}

variable "admin_password" {
  description = "Windows VM admin password"
  type        = string
  sensitive   = true
}

variable "my_public_ip" {
  description = "Your public IP address for RDP access"
  type        = string
}