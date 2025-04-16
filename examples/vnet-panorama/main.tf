# Example deployment of a Palo Alto firewall with Panorama management in a Virtual Network

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "rg-example"
  location = "West Europe"
}

resource "azurerm_virtual_network" "example" {
  name                = "vnet-example"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "trust" {
  name                 = "subnet-trust"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
  
  delegation {
    name = "trusted"
    
    service_delegation {
      name = "PaloAltoNetworks.Cloudngfw/firewalls"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_subnet" "untrust" {
  name                 = "subnet-untrust"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
  
  delegation {
    name = "untrusted"
    
    service_delegation {
      name = "PaloAltoNetworks.Cloudngfw/firewalls"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_public_ip" "example" {
  name                = "pip-example"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

module "palo_alto_firewall" {
  source = "../../"
  
  # Core settings
  firewall_type         = "vnet_panorama"
  name                  = "fw-example"
  resource_group_name   = azurerm_resource_group.example.name
  location              = azurerm_resource_group.example.location
  panorama_base64_config = "e2RnbmFtZTogY25nZnctYXotZXhhbXBsZSwgdHBsbmFtZTogY25nZnctZXhhbXBsZS10ZW1wbGF0ZS1zdGFjaywgZXhhbXBsZS1wYW5vcmFtYS1zZXJ2ZXI6IDE5Mi4xNjguMC4xLCB2bS1hdXRoLWtleTogMDAwMDAwMDAwMDAwMDAwLCBleHBpcnk6IDIwMjQvMDcvMzF9Cg=="
  
  # Network settings
  public_ip_address_ids = [azurerm_public_ip.example.id]
  virtual_network_id    = azurerm_virtual_network.example.id
  trusted_subnet_id     = azurerm_subnet.trust.id
  untrusted_subnet_id   = azurerm_subnet.untrust.id
  
  # DNS settings
  use_azure_dns = true
  
  # Tags
  tags = {
    Environment = "Example"
    Department  = "Security"
  }
}

output "firewall_id" {
  value = module.palo_alto_firewall.firewall_id
}

output "panorama_details" {
  value = module.palo_alto_firewall.panorama_details
}