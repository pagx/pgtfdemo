resource "azurerm_private_dns_zone" "pgtfdemo_private_dns_zone" {
  for_each = local.private_dns_zones
  name = each.value.name
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "pgtfdemo_private_dns_zone_vnet_link" {
  for_each = local.private_dns_zones
  name                  = "pgtfvent-${each.key}-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.pgtfdemo_private_dns_zone[each.key].name
  virtual_network_id    = azurerm_virtual_network.pgtfdemo_vnet.id
}

resource "azurerm_storage_account" "pgtfdemo_sa" {
    name = "pginfrademo${var.environment_name}sa"
    resource_group_name   = azurerm_resource_group.main.name
    location            = azurerm_resource_group.main.location
    account_tier             = "Standard"
    account_replication_type = "LRS"
    min_tls_version                 = "TLS1_2"
    allow_nested_items_to_be_public = false
    public_network_access_enabled = false

    network_rules {
        default_action = "Deny"
        bypass = [ "AzureServices" ]
        virtual_network_subnet_ids = [azurerm_subnet.pgtfdemo_appsvcs_snet.id]
    }

    tags = {
      BuildBy = "${local.buildby_tag}"
      BuildDate = "${local.pgtfbuild-datestamp}"
      Environment = var.environment_name
    }
}

resource "azurerm_storage_share" "pgtfdemo_la_share" {
    name = "${var.environment_name}pgtfdemosalashare"
    storage_account_name = azurerm_storage_account.pgtfdemo_sa.name
    quota = 50
}

resource "azurerm_private_endpoint" "pgtfdemo_sa_pe" {
  for_each = toset(local.sa_types)
  name = "${azurerm_storage_account.pgtfdemo_sa.name}-${each.key}-pe"
  location = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id = azurerm_subnet.pgtfdemo_pe_snet.id

  private_service_connection {
    name = "${azurerm_storage_account.pgtfdemo_sa.name}-${each.key}-priv-svc-conn"
    is_manual_connection = false
    private_connection_resource_id = azurerm_storage_account.pgtfdemo_sa.id
    subresource_names = [ each.key ]
  }

  private_dns_zone_group {
    name = "${each.key}-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.pgtfdemo_private_dns_zone[each.key].id]
  } 
}

resource "azurerm_service_plan" "pgtfdemo_app_svc_plan" {
  name = "${local.asp_name}"
  resource_group_name = azurerm_resource_group.main.name
  location = azurerm_resource_group.main.location
  os_type = "Windows"
  sku_name = "WS1"
}

resource "azurerm_logic_app_standard" "pgtfdemo_la" {
  depends_on = [ azurerm_private_endpoint.pgtfdemo_sa_pe ]
  name = "${var.environment_name}pginfratfdemola"
  location = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  storage_account_name = azurerm_storage_account.pgtfdemo_sa.name
  storage_account_access_key = azurerm_storage_account.pgtfdemo_sa.primary_access_key
  app_service_plan_id = azurerm_service_plan.pgtfdemo_app_svc_plan.id
  virtual_network_subnet_id = azurerm_subnet.pgtfdemo_appsvcs_snet.id
  https_only = true
  version = "~4"
  app_settings = {
    "WEBSITE_CONTENTOVERVNET" : "1"
    "FUNCTIONS_WORKER_RUNTIME" : "node"
    "WEBSITE_NODE_DEFAULT_VERSION" : "~18"
  }
  site_config {
    use_32_bit_worker_process = true
    ftps_state = "Disabled"
    websockets_enabled = false
    min_tls_version = "1.2"
    runtime_scale_monitoring_enabled = false
    vnet_route_all_enabled = true
  }
}

resource "azurerm_private_endpoint" "pgtfdemo_la_pe" {
  name = "${azurerm_logic_app_standard.pgtfdemo_la.name}-pe"
  location = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id = azurerm_subnet.pgtfdemo_pe_snet

  private_service_connection {
    name = "${azurerm_logic_app_standard.pgtfdemo_la.name}-priv-svc-conn"
    is_manual_connection = false
    private_connection_resource_id = azurerm_logic_app_standard.pgtfdemo_la.id
    subresource_names = [ "sites" ]
  }

  private_dns_zone_group {
    name = "la-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.pgtfdemo_private_dns_zone["la"].id]
  } 
}
