// Copyright 2020 Google LLC All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Run:
// terraform apply -var project="<YOUR_GCP_ProjectID>"

provider "google" {
  version = "~> 3.35"
}

provider "google-beta" {
  version = "~> 3.35"
}

variable "project" {
  description = "The Google Cloud Project to apply this to"
}

/* Realms */

resource "google_game_services_realm" "us" {
  project  = var.project

  realm_id  = "united-states"
  time_zone = "PST8PDT"
  location  = "global"

  description = "US Game Players"
}

/* US Region */

module "game-cluster-us-1" {
  source  = "./agones-cluster"
  project = var.project

  name  = "game-cluster-us-1"
  zone  = "us-central1-a"
  realm = google_game_services_realm.us.realm_id
}

/* Configurations and Deployments */

resource "google_game_services_game_server_deployment" "udp" {
  project  = var.project

  deployment_id = "udp"
  description   = "Simple UDP server"
}

resource "google_game_services_game_server_config" "v1" {
  project  = var.project

  config_id     = "v1"
  deployment_id = google_game_services_game_server_deployment.udp.deployment_id
  description   = "Version 1 of the Simple UDP Fleet"

  fleet_configs {
    name       = "simple-udp"
    fleet_spec = jsonencode(yamldecode(file("./configs/fleet-v1-tf.yaml")))
  }
}

/* Roll out the Deployment */

resource "google_game_services_game_server_deployment_rollout" "default" {
  project  = var.project

  deployment_id              = google_game_services_game_server_deployment.udp.deployment_id
  default_game_server_config = google_game_services_game_server_config.v1.name
}
