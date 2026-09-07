packer {
  required_plugins {
    oracle = {
      source  = "github.com/hashicorp/oracle"
      version = "~> 1"
    }
  }
}

locals {
  build_timestamp = formatdate("MMDDhhmm", timestamp())
}

source "oracle-oci" "postgresql_ubuntu" {

  # auth vars
  region       = var.oci_region
  tenancy_ocid = var.oci_tenancy_ocid
  user_ocid    = var.oci_user_ocid
  key_file     = var.oci_key_file
  fingerprint  = var.oci_fingerprint

  # Image
  base_image_filter {
    operating_system         = "Canonical Ubuntu"
    operating_system_version = "26.04"
    shape                    = "VM.Standard.E5.Flex"
  }
  shape = "VM.Standard.E5.Flex"
  shape_config {
    ocpus         = 1
    memory_in_gbs = 16
  }

  compartment_ocid    = var.compartment_ocid
  availability_domain = var.availability_domain

  subnet_ocid    = var.subnet_ocid
  use_private_ip = true
  create_vnic_details {
    assign_public_ip = false
    nsg_ids          = [var.build_nsg_ocid]
  }

  image_name    = "pg-ubuntu-${local.build_timestamp}"
  instance_name = "vm-pg-ubuntu-build"

  ssh_username = "ubuntu"
  skip_create_image = false
}

build {
  name    = "postgresql-ubuntu"
  sources = ["source.oracle-oci.postgresql_ubuntu"]

  provisioner "shell" {
    environment_vars = [
      "POSTGRESQL_MAJOR=${var.postgresql_major}",
    ]
    execute_command = "sudo -S sh -c '{{ .Vars }} {{ .Path }}'"
    script          = "${path.root}/install-postgresql.sh"
  }

  # This is deliberately the last provisioner. It removes build identity and
  # cloud-init state, then enables a deny-by-default host firewall. A later
  # cloud-init run opens only the instance's approved SSH and PostgreSQL CIDRs.
  provisioner "shell" {
    environment_vars = [
      "BUILD_SSH_USERNAME=ubuntu",
    ]
    execute_command = "sudo -E bash '{{ .Path }}'"
    script          = "${path.root}/finalize-image.sh"
  }
}
