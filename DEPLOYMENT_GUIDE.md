# Azure Cloud Infrastructure Automation Lab

## Project Overview

This project demonstrates an end-to-end Azure infrastructure automation workflow. The lab starts with manually deploying Azure resources through the Azure Portal, then recreating the same environment using Terraform, and finally automating deployment through GitHub Actions using Azure OIDC authentication.

The purpose of this project is to show how a cloud environment can move from a manual build process to a repeatable Infrastructure as Code deployment pipeline.

---

## Architecture

```text
Resource Group
│
├── Virtual Network: vnet-cloud-lab-tf
│   ├── WebSubnet: 10.30.1.0/24
│   └── DatabaseSubnet: 10.30.2.0/24
│
├── Network Security Groups
│   ├── nsg-web-tf
│   └── nsg-database-tf
│
├── Virtual Machines
│   ├── vm-web-tf-01
│   └── vm-db-tf-01
│
├── Storage Account
│
├── Private Endpoint
│
└── Private DNS Zone
```

---

## Skills Demonstrated

- Azure Virtual Networks
- Subnet design
- Network Security Groups
- Windows Server VM deployment
- Azure Storage Accounts
- Private Endpoints
- Private DNS Zones
- Terraform Infrastructure as Code
- Remote Terraform state
- GitHub Actions CI/CD
- Azure OIDC authentication
- Secure cloud network segmentation

---

## Resources Deployed

| Resource | Purpose |
|---|---|
| Resource Group | Holds all lab resources |
| Virtual Network | Provides private Azure network space |
| Web Subnet | Hosts the public-facing web VM |
| Database Subnet | Hosts the private backend VM and private endpoint |
| Web NSG | Allows RDP from trusted IP and HTTPS traffic |
| Database NSG | Allows RDP only from the Web subnet |
| Web VM | Jump box / web-tier server |
| Database VM | Private backend server |
| Storage Account | Secure storage service |
| Private Endpoint | Provides private access to the Storage Account |
| Private DNS Zone | Resolves private endpoint DNS records |

---

## Network Security Design

The lab uses two separate subnets to simulate a basic multi-tier cloud architecture.

### Web Subnet

The Web subnet allows limited inbound access:

```text
Allow RDP from trusted public IP
Allow HTTPS on port 443
Deny all other inbound internet traffic
```

### Database Subnet

The Database subnet is more restricted:

```text
Allow RDP from WebSubnet only
No public IP assigned to database VM
Storage Account access through Private Endpoint
```

This design prevents the database VM and storage account from being directly exposed to the public internet.

---

## Prerequisites

Before deploying this project, install or configure the following:

- Azure subscription
- Azure CLI
- Terraform
- Git
- GitHub account
- Visual Studio Code or preferred code editor
- Permission to create Azure resources
- Permission to create an App Registration in Microsoft Entra ID

Verify Azure CLI access:

```powershell
az login
az account show
```

Verify Terraform:

```powershell
terraform version
```

---

## Manual Deployment Steps

This project was first built manually in the Azure Portal to understand the architecture before automating it with Terraform.

### 1. Create Resource Group

```text
Name: rg-cloud-lab-manual
Region: East US
```

### 2. Create Virtual Network

```text
Name: vnet-cloud-lab
Address Space: 10.20.0.0/16
```

Create two subnets:

```text
WebSubnet: 10.20.1.0/24
DatabaseSubnet: 10.20.2.0/24
```

### 3. Create Web NSG

Associate the NSG to `WebSubnet`.

Inbound rules:

```text
Allow-RDP-From-MyIP
Port: 3389
Source: My public IP
Priority: 100

Allow-HTTPS
Port: 443
Source: Internet
Priority: 110

Deny-Internet-Inbound
Port: *
Source: Internet
Priority: 200
```

### 4. Create Database NSG

Associate the NSG to `DatabaseSubnet`.

Inbound rule:

```text
Allow-RDP-From-WebSubnet
Port: 3389
Source: 10.20.1.0/24
Priority: 100
```

### 5. Create Virtual Machines

Create the Web VM:

```text
Name: vm-web-01
Subnet: WebSubnet
Public IP: Yes
```

Create the Database VM:

```text
Name: vm-db-01
Subnet: DatabaseSubnet
Public IP: No
```

### 6. Create Storage Account with Private Endpoint

```text
Public network access: Disabled
Private Endpoint subnet: DatabaseSubnet
Target sub-resource: blob
Private DNS integration: Enabled
Encryption: Microsoft-managed keys
```

---

## Connectivity Testing

After deploying the manual environment, RDP into the Web VM and test connectivity to the Database VM.

From PowerShell on the Web VM:

```powershell
Test-NetConnection <db-private-ip> -Port 3389
```

Expected result:

```text
TcpTestSucceeded : True
```

Test a blocked port:

```powershell
Test-NetConnection <db-private-ip> -Port 80
```

Expected result:

```text
TcpTestSucceeded : False
```

This validates that RDP from the Web subnet to the Database subnet is allowed while other traffic is blocked.

---

## Terraform Deployment

The environment was then recreated using Terraform.

### Project Structure

```text
azure-cloud-lab-terraform
│
├── backend.tf
├── providers.tf
├── variables.tf
├── main.tf
├── outputs.tf
├── terraform.tfvars.example
├── .gitignore
└── .github
    └── workflows
        └── terraform.yml
```

---

## Terraform Files

### providers.tf

```hcl
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
  use_oidc        = true
}
```

### backend.tf

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "REPLACE_WITH_STATE_STORAGE_ACCOUNT"
    container_name       = "tfstate"
    key                  = "azure-cloud-lab.tfstate"
  }
}
```

### variables.tf

```hcl
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
  description = "Trusted public IP address for RDP access"
  type        = string
}
```

---

## Local Terraform Deployment

Create a local `terraform.tfvars` file.

Do not commit this file to GitHub.

```hcl
subscription_id = "your-subscription-id"
location        = "eastus"
my_public_ip    = "your-public-ip"
admin_username  = "azureadmin"
admin_password  = "YourStrongPasswordHere!"
```

Run:

```powershell
terraform fmt
terraform init
terraform validate
terraform plan
terraform apply
```

Approve the deployment:

```text
yes
```

---

## Remote Terraform State

A remote backend is used to store Terraform state in Azure Storage.

Create the state resource group:

```powershell
az group create `
  --name rg-tfstate `
  --location eastus
```

Create the storage account:

```powershell
$RANDOM_SUFFIX = Get-Random -Minimum 10000 -Maximum 99999
$STORAGE_ACCOUNT = "sttfstate$RANDOM_SUFFIX"

az storage account create `
  --name $STORAGE_ACCOUNT `
  --resource-group rg-tfstate `
  --location eastus `
  --sku Standard_LRS
```

Create the container:

```powershell
az storage container create `
  --name tfstate `
  --account-name $STORAGE_ACCOUNT `
  --auth-mode login
```

Update `backend.tf` with the storage account name.

Then run:

```powershell
terraform init -reconfigure
```

---

## GitHub Actions Deployment

This project uses GitHub Actions to automatically deploy Terraform to Azure.

Authentication is handled through Azure OIDC instead of a stored client secret.

---

## Azure OIDC Setup

### 1. Create App Registration

Go to:

```text
Microsoft Entra ID → App registrations → New registration
```

Use:

```text
Name: github-terraform-oidc-lab
Supported account types: Single tenant
```

Copy:

```text
Application client ID
Directory tenant ID
```

### 2. Assign Azure Role

Go to:

```text
Subscriptions → Access control (IAM) → Add role assignment
```

Assign:

```text
Role: Contributor
Member: github-terraform-oidc-lab
Scope: Subscription
```

### 3. Add Federated Credential

Go to:

```text
App registration → Certificates & secrets → Federated credentials → Add credential
```

Use:

```text
Scenario: GitHub Actions deploying Azure resources
Organization: <your-github-username>
Repository: azure-cloud-lab-terraform
Entity type: Branch
Branch: main
Name: github-main-terraform
```

---

## GitHub Repository Secrets

Add the following secrets to the GitHub repository:

```text
AZURE_CLIENT_ID
AZURE_TENANT_ID
AZURE_SUBSCRIPTION_ID
VM_ADMIN_PASSWORD
MY_PUBLIC_IP
```

Path:

```text
GitHub Repository → Settings → Secrets and variables → Actions
```

---

## GitHub Actions Workflow

Create:

```text
.github/workflows/terraform.yml
```

Add:

```yaml
name: Terraform Azure Deployment

on:
  push:
    branches:
      - main
  workflow_dispatch:

permissions:
  id-token: write
  contents: read

env:
  ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
  ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
  ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
  ARM_USE_OIDC: true

  TF_VAR_subscription_id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
  TF_VAR_admin_password: ${{ secrets.VM_ADMIN_PASSWORD }}
  TF_VAR_my_public_ip: ${{ secrets.MY_PUBLIC_IP }}

jobs:
  terraform:
    name: Terraform Plan and Apply
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3

      - name: Terraform Format Check
        run: terraform fmt -check

      - name: Terraform Init
        run: terraform init

      - name: Terraform Validate
        run: terraform validate

      - name: Terraform Plan
        run: terraform plan

      - name: Terraform Apply
        run: terraform apply -auto-approve
```

---

## Push to GitHub

```powershell
git init
git add .
git commit -m "Initial Azure Terraform lab"
git branch -M main
git remote add origin https://github.com/YOURUSERNAME/azure-cloud-lab-terraform.git
git push -u origin main
```

After pushing to the `main` branch, GitHub Actions will run automatically.

---

## Validation After GitHub Actions Deployment

After the workflow completes, verify the deployed resource group in Azure:

```text
rg-cloud-lab-terraform
```

Confirm the following resources exist:

```text
vnet-cloud-lab-tf
WebSubnet
DatabaseSubnet
nsg-web-tf
nsg-database-tf
vm-web-tf-01
vm-db-tf-01
Storage Account
Private Endpoint
Private DNS Zone
```

RDP into the Web VM and test:

```powershell
Test-NetConnection <db-private-ip> -Port 3389
```

Expected:

```text
TcpTestSucceeded : True
```

Then test:

```powershell
Test-NetConnection <db-private-ip> -Port 80
```

Expected:

```text
TcpTestSucceeded : False
```

---

## Cleanup

To remove Terraform-created resources:

```powershell
terraform destroy
```

To remove manually created resources:

```text
Delete rg-cloud-lab-manual from the Azure Portal
```

Only delete the Terraform state resource group after you are completely finished with the project:

```text
rg-tfstate
```

---

## Troubleshooting

### GitHub Actions authentication fails

Check:

```text
AZURE_CLIENT_ID
AZURE_TENANT_ID
AZURE_SUBSCRIPTION_ID
Federated credential branch name
Repository name
```

### Terraform state backend fails

Check:

```text
Storage account name
Container name
Backend resource group
RBAC permissions
```

### RDP to Web VM fails

Check:

```text
Web VM public IP
Web NSG rule
Your current public IP
Windows firewall
VM running state
```

### Web VM cannot reach Database VM

Check:

```text
Database VM private IP
Database NSG rule
Source address prefix
Effective security rules
Windows firewall
```

---

## Screenshots to Capture

For portfolio documentation, capture:

```text
1. Resource group overview
2. VNet address space
3. WebSubnet and DatabaseSubnet
4. Web NSG rules
5. Database NSG rules
6. Web VM overview
7. Database VM overview
8. Storage account networking tab
9. Private endpoint configuration
10. Private DNS zone
11. Test-NetConnection results
12. Terraform plan output
13. GitHub Actions successful workflow
14. Azure resources created by Terraform
```

---

## Resume Bullets

- Built a multi-tier Azure lab environment using VNets, subnets, NSGs, Windows Server VMs, Storage Accounts, and Private Endpoints to simulate secure cloud network segmentation.

- Refactored Azure infrastructure into Terraform and configured remote state using Azure Storage to support repeatable infrastructure deployment and state locking.

- Implemented GitHub Actions CI/CD with Azure OIDC authentication to automate Terraform validation, planning, and deployment without storing long-lived Azure credentials.

---

## Project Summary

This project demonstrates how Azure infrastructure can be manually deployed, converted into Infrastructure as Code, and automated through a secure CI/CD pipeline. It highlights practical skills in Azure networking, Terraform, GitHub Actions, identity-based authentication, and secure cloud architecture.
