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

variable "project_name" {
  description = "GCP project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment. This will be used for resource naming."
  type        = string
}

variable "vpc_name" {
  description = "VPC name"
  type        = string
}

variable "filestore_tier" {
  description = "Filestore tier"
  type        = string
}

variable "filestore_capacity_gb" {
  description = "Filestore capacity in GB"
  type        = number
}

variable "filestore_location" {
  description = "Filestore location"
  type        = string
}

variable "filestore_name" {
  description = "File share name"
  type        = string
}
