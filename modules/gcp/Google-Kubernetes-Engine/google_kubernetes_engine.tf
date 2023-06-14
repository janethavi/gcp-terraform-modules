# -------------------------------------------------------------------------------------
#
# Copyright (c) 2023, WSO2 LLC. (http://www.wso2.com). All Rights Reserved.
#
# This software is the property of WSO2 LLC. and its suppliers, if any.
# Dissemination of any information or reproduction of any material contained
# herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
# You may not alter or remove any copyright or other notice from copies of this content.
#
# --------------------------------------------------------------------------------------

resource "google_container_cluster" "cluster" {
  name        = join("-", ["gke", var.project, var.cluster_location])
  project     = var.project
  description = join("", ["GKE cluster for ", var.project, " located in ", var.cluster_location])

  # Regional cluster
  location                  = var.cluster_location
  enable_kubernetes_alpha   = false
  enable_l4_ilb_subsetting  = false
  enable_tpu                = false
  default_max_pods_per_node = var.default_max_pods_per_node

  # Setting the value to 1 as it will be the minimum number to remove the default node pool
  initial_node_count       = 1
  remove_default_node_pool = true

  # network configuration
  network    = var.vpc_id
  subnetwork = google_compute_subnetwork.cluster_subnetwork.name
  private_cluster_config {
    enable_private_endpoint = true
    enable_private_nodes    = true
    master_ipv4_cidr_block  = var.master_cluster_ipv4_cidr
  }
  ip_allocation_policy {
    cluster_secondary_range_name  = "cluster-pods"
    services_secondary_range_name = "cluster-services"
  }
  default_snat_status {
    disabled = false
  }
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = var.master_authorized_networks_cidr
      display_name = " Authorized network to access CP"
    }
  }
  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }
  workload_identity_config {
    workload_pool = join(".", [var.project, "svc.id.goog"])
  }
  release_channel {
    channel = "UNSPECIFIED"
  }
  cluster_autoscaling {
    enabled = true
    resource_limits {
      maximum       = 16
      minimum       = 0
      resource_type = "cpu"
    }
    resource_limits {
      maximum       = 30
      minimum       = 0
      resource_type = "memory"
    }
    auto_provisioning_defaults {
      disk_type       = "pd-balanced"
      image_type      = "COS_CONTAINERD"
      service_account = google_service_account.cluster_service_account.email
      management {
        auto_repair  = true
        auto_upgrade = false
      }
      upgrade_settings {
        max_surge       = 1
        max_unavailable = 0
        strategy        = "SURGE"
      }
    }
  }
  addons_config {
    horizontal_pod_autoscaling {
      disabled = false
    }
    http_load_balancing {
      disabled = false
    }
    gcp_filestore_csi_driver_config {
      enabled = true
    }
    gke_backup_agent_config {
      enabled = true
    }
    gce_persistent_disk_csi_driver_config {
      enabled = true
    }
    network_policy_config {
      disabled = true
    }
    dns_cache_config {
      enabled = false
    }
  }
  vertical_pod_autoscaling {
    enabled = true
  }
  confidential_nodes {
    enabled = false
  }
  logging_config {
    enable_components = [
      "SYSTEM_COMPONENTS",
      "WORKLOADS"
    ]
  }

  depends_on = [
    google_compute_subnetwork.cluster_subnetwork,
    google_service_account.cluster_service_account
  ]
}

resource "google_container_node_pool" "node_pool" {
  name           = join("", ["gkenpprimary"])
  project        = var.project
  location       = var.node_pool_location
  cluster        = google_container_cluster.cluster.id
  node_count     = var.node_pool_node_count
  node_locations = var.node_pool_zone_locations

  node_config {
    preemptible     = false
    machine_type    = var.node_pool_machine_type
    service_account = google_service_account.cluster_service_account.email
    image_type      = "COS_CONTAINERD"
    local_ssd_count = 0
    disk_size_gb    = 100
    disk_type       = "pd-balanced"
    metadata = {
      "disable-legacy-endpoints" = "true"
    }
    labels = {
      "node-pool" = "primary"
    }
  }
  management {
    auto_repair  = true
    auto_upgrade = false
  }
  network_config {
    enable_private_nodes = true
    create_pod_range     = false
    pod_range            = "cluster-pods"
  }
  autoscaling {
    max_node_count  = var.node_pool_max_node_count
    min_node_count  = var.node_pool_min_node_count
    location_policy = "BALANCED"
  }
  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
    strategy        = "SURGE"
  }

  depends_on = [
    google_service_account.cluster_service_account
  ]
}