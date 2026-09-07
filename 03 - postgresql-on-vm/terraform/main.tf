locals {
  postgresql_cloud_init = templatefile("postgresql-instance.yaml", {
    admin_cidr                   = var.admin_cidr
    data_volume_device           = var.data_volume_device
    data_volume_mount_point      = var.data_volume_mount_point
    data_volume_wait_seconds     = var.data_volume_wait_seconds
    initialize_empty_data_volume = var.initialize_empty_data_volume
    postgresql_client_cidr       = var.postgresql_client_cidr
    postgresql_major             = var.postgresql_major
    postgresql_port              = var.postgresql_port
    tls_cert_file                = var.tls_cert_file
    tls_key_file                 = var.tls_key_file
    tls_mode                     = var.tls_mode
  })
}

data "oci_identity_availability_domains" "all" {
	compartment_id = var.compartment_ocid
}

resource "random_shuffle" "ad" {
	# Refer to https://registry.terraform.io/providers/oracle/oci/latest/docs/data-sources/identity_availability_domains#availabilitydomain-reference
	# to learn all the properties available different that `name`
	input        = [for ad in data.oci_identity_availability_domains.all.availability_domains : ad.name]
	result_count = 1
}

# A supplied existing_data_volume_id lets a separate storage lifecycle own the
# volume. Otherwise this stack creates it once and protects it from a normal
# terraform destroy; VM replacement never destroys the volume in either mode.
resource "oci_core_volume" "postgresql_data" {

  availability_domain = one(random_shuffle.ad.result)
  compartment_id      = var.compartment_ocid
  display_name        = "bv-postgresql-data"
  size_in_gbs         = var.data_volume_size_gbs
  vpus_per_gb         = var.data_volume_vpus_per_gb

  lifecycle {
    prevent_destroy = true
  }
}

# This resource turns a change to the image or first-boot configuration into an
# instance replacement. It intentionally does not include volume VPU settings:
# OCI can change them online while the same VM and data volume remain attached.
resource "terraform_data" "postgresql_release" {
  triggers_replace = {
    image_ocid              = var.image_ocid
    postgresql_cloud_init   = sha256(local.postgresql_cloud_init)
    postgresql_major        = var.postgresql_major
    data_volume_mount_point = var.data_volume_mount_point
  }
}

resource "oci_core_instance" "postgresql" {
  availability_domain = "ODaf:EU-STOCKHOLM-1-AD-1"
  compartment_id      = var.compartment_ocid
  display_name        = "vm-postgresql"
  shape               = "VM.Standard.E5.Flex"

  shape_config {
    ocpus         = var.ocpus
    memory_in_gbs = var.memory_in_gbs
  }

  create_vnic_details {
    subnet_id        = var.subnet_ocid

    assign_public_ip = false
    nsg_ids          = [var.nsg_ocid]
  }

  source_details {
    source_type = "image"
    source_id   = var.image_ocid
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key)
    user_data           = base64encode(local.postgresql_cloud_init)
  }

  lifecycle {
    # A PostgreSQL filesystem must have a single writer. Destroy the old VM and
    # its attachment before the replacement tries to attach the same volume.
    create_before_destroy = false
    replace_triggered_by  = [terraform_data.postgresql_release]
  }
}

resource "oci_core_volume_attachment" "postgresql_data" {
  attachment_type                     = "paravirtualized"
  device                              = var.data_volume_device
  display_name                        = "$bvattch-postgresql-data"
  instance_id                         = oci_core_instance.postgresql.id
  is_pv_encryption_in_transit_enabled = false
  volume_id                           = oci_core_volume.postgresql_data.id
}

output "instance_id" {
  value = oci_core_instance.postgresql.id
}

output "private_ip" {
  value = oci_core_instance.postgresql.private_ip
}
