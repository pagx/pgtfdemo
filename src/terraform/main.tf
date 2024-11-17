resource azurerm_resource_group main {
  name     = "rg-${var.application_name}-${var.environment_name}"
  location = var.location
}
resource "azurerm_virtual_network" "pgtfdemo_vnet" {
  name                = "pg-infra-demo-vnet"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.159.40.0/21"]
  dns_servers         = ["168.63.129.16"]
  tags = {
    BuildBy = "${local.buildby_tag}"
    BuildDate = "${local.pgtfbuild-datestamp}"
    Environment = var.environment_name
  }
}
resource "azurerm_subnet" "pgtfdemo_pe_snet" {
  name             = "pg-infra-demo-pe-snet"
  resource_group_name = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.pgtfdemo_vnet.name
  address_prefixes = ["10.159.41.0/26"]
}
resource "azurerm_subnet" "pgtfdemo_appsvcs_snet" {
  name             = "pg-infra-demo-appsvcs-snet"
  resource_group_name = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.pgtfdemo_vnet.name
    address_prefixes = ["10.159.41.64/26"]
     delegation {
      name = "delegation"
      service_delegation{
        name = "Microsoft.Web/serverFarms"
        actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
  }