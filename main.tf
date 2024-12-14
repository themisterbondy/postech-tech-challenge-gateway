terraform {
  required_version = ">= 1.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.0.0"
    }
  }
}

variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

# Configure o provedor do Azure
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "resource_group_name" {
  type    = string
  default = "rg-postech-fiap-appgw"
}

variable "appgw_name" {
  type    = string
  default = "postech-fiap-appgw"
}

variable "function_host_name" {
  type    = string
  default = "postech-fiap-serverless.azurewebsites.net"
}

variable "vnet_name" {
  type    = string
  default = "postech-fiap-vnet-appgw"
}

variable "subnet_name" {
  type    = string
  default = "postech-fiap-subnet-appgw"
}

resource "azurerm_virtual_network" "this" {
  name                = var.vnet_name
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "this" {
  name                 = var.subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "this" {
  name                = "${var.appgw_name}-public-ip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_application_gateway" "this" {
  name                = var.appgw_name
  resource_group_name = var.resource_group_name
  location            = var.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "appgw-ip-config"
    subnet_id = azurerm_subnet.this.id
  }

  frontend_ip_configuration {
    name                 = "appgw-frontend-ip"
    public_ip_address_id = azurerm_public_ip.this.id
  }

  frontend_port {
    name = "port-80"
    port = 80
  }

  # Backend para a Function (usando FQDN)
  backend_address_pool {
    name  = "function-backend-pool"
    fqdns = [var.function_host_name]
  }

  backend_http_settings {
    name                  = "function-http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 443
    protocol              = "Https"
    request_timeout       = 30
    host_name             = var.function_host_name
  }

  url_path_map {
    name                               = "appgw-path-map"
    default_backend_address_pool_name  = "function-backend-pool"
    default_backend_http_settings_name = "function-http-settings"

    path_rule {
      name                       = "api-paths"
      paths                      = ["/api/*"]
      backend_address_pool_name  = "function-backend-pool"
      backend_http_settings_name = "function-http-settings"
    }
  }

  http_listener {
    name                           = "listener-80"
    frontend_ip_configuration_name = "appgw-frontend-ip"
    frontend_port_name             = "port-80"
    protocol                       = "Http"
  }

  request_routing_rule {
    name               = "rule-path-based"
    rule_type          = "PathBasedRouting"
    http_listener_name = "listener-80"
    url_path_map_name  = "appgw-path-map"
    priority           = 100
  }

  tags = {
    project = "postech-fiap"
  }
}
