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

variable "name" {
  description = "The name of the GKE cluster"
  type        = string
}
variable "zone" {
  description = "The Google Cloud Zone to place the GKE cluster"
  type        = string
}
variable "project" {
  description = "The Google Cloud project name"
  type        = string
}
variable "realm" {
  description = "The name of the realm to register this GKE+Agones cluster to"
  type        = string
}

variable "machine_type" {
  default     = "n1-standard-4"
  description = "The GCE machine type to use for the nodes"
  type        = string
}

variable "node_count" {
  default     = "4"
  description = "This is the number of gameserver nodes. The Agones module will automatically create an additional two node pools with 1 node each for 'agones-system' and 'agones-metrics'"
  type        = number
}

variable "network" {
  default     = "default"
  description = "The name of the VPC network to attach the cluster and firewall rule to"
  type        = string
}
