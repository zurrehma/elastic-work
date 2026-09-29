provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

resource "azurerm_resource_group" "this" {
  name     = "${var.name}-rg"
  location = var.location
}

resource "azurerm_kubernetes_cluster" "this" {
  name                = var.name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  dns_prefix          = var.name

  default_node_pool {
    name       = "elastic"
    vm_size    = var.node_vm_size
    node_count = 3
    zones      = ["1", "2", "3"]
  }

  identity {
    type = "SystemAssigned"
  }

  # Classic, manually sized node pools (not Node Auto Provisioning).
  node_provisioning_profile {
    mode = "Manual"
  }
}

provider "helm" {
  kubernetes = {
    host                   = azurerm_kubernetes_cluster.this.kube_config[0].host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.this.kube_config[0].client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.this.kube_config[0].client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.this.kube_config[0].cluster_ca_certificate)
  }
}

module "eck" {
  source = "../../modules/eck"
  # AKS built-in Azure Disk CSI class.
  storage_class_name = "managed-csi"

  depends_on = [azurerm_kubernetes_cluster.this]
}
