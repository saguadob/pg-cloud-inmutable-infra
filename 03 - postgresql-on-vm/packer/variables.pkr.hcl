variable "oci_region" {
  type = string
}

variable "oci_tenancy_ocid" {
  type = string
}

variable "oci_user_ocid" {
  type = string
}

variable "oci_key_file" {
  type = string
}

variable "oci_fingerprint" {
  type = string
}

variable "compartment_ocid" {
  type        = string
  description = "OCI compartment that holds the temporary builder instance and resulting custom image."
}

variable "availability_domain" {
  type        = string
  description = "OCI availability domain in which Packer launches the temporary builder instance."
}

variable "subnet_ocid" {
  type        = string
  description = "Subnet for the temporary builder. Use a dedicated build subnet, not a production database subnet."
}

variable "build_nsg_ocid" {
  type        = string
  description = "NSGs for the temporary build VNIC. They must allow SSH from the Packer runner and outbound package access."
}

variable "postgresql_major" {
  type        = string
  description = "PostgreSQL major version supplied by the selected Ubuntu repositories, for example 16."
  default     = "16"
}
