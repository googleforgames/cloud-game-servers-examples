# Copyright 2020 Google LLC All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


terraform {
  required_providers {
    google      = "~> 3.35"
    google-beta = "~> 3.35"
  }
}

// Create a GKE cluster with the appropriate structure
module "agones_cluster" {
  source = "git::https://github.com/googleforgames/agones.git//install/terraform/modules/gke/?ref=release-1.8.0"

  cluster = {
    "name"             = var.name
    "zone"             = var.zone
    "machineType"      = var.machine_type
    "initialNodeCount" = var.node_count
    "project"          = var.project
    "network"          = var.network
  }
}

// Install Agones via Helm
module "helm_agones" {
  source = "git::https://github.com/googleforgames/agones.git//install/terraform/modules/helm3/?ref=release-1.8.0"

  agones_version         = "1.8.0"
  values_file            = ""
  chart                  = "agones"
  host                   = module.agones_cluster.host
  token                  = module.agones_cluster.token
  cluster_ca_certificate = module.agones_cluster.cluster_ca_certificate
}

// Install cert-manager.io
provider "helm" {
  version = "~> 1.2"

  debug           = true

  kubernetes {
    load_config_file       = false
    host                   = module.agones_cluster.host
    token                  = module.agones_cluster.token
    cluster_ca_certificate = module.agones_cluster.cluster_ca_certificate
  }
}

data "helm_repository" "jetstack" {
  name = "jetstack"
  url  = "https://charts.jetstack.io"

  depends_on = [module.helm_agones]
}

resource "helm_release" "cert_manager" {
  name = "cert-manager"
  force_update = "true"
  repository = data.helm_repository.jetstack.metadata.0.name
  chart = "cert-manager"
  version = "v0.15.1"
  timeout = 420
  namespace = "cert-manager"
  create_namespace = true

  set {
    name  = "installCRDs"
    value = true
  }
}

// Register the cluster with the realm
resource "google_game_services_game_server_cluster" "registry" {
  project    = var.project
  depends_on = [module.agones_cluster, module.helm_agones, helm_release.cert_manager]

  cluster_id = var.name
  realm_id   = var.realm
  timeouts {
    create = "10m"
  }

  connection_info {
    gke_cluster_reference {
      cluster = "locations/${var.zone}/clusters/${var.name}"
    }
    namespace = "default"
  }
}
