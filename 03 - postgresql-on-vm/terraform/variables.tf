variable "compartment_ocid" {
  description = "Compartment in which the test resources are created."
  type        = string
}

variable "image_ocid" {
  description = "OCID of the immutable PostgreSQL Packer image, compatible with the selected shape. Changing it replaces the VM but retains the data volume."
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key injected by OCI cloud-init for approved administration."
  type        = string
}

variable "admin_cidr" {
  description = "CIDR permitted to reach SSH (TCP/22). Do not use a broad internet CIDR."
  type        = string

  validation {
    condition     = !contains(["0.0.0.0/0", "::/0"], var.admin_cidr)
    error_message = "admin_cidr must not expose SSH to the internet."
  }
}

variable "postgresql_client_cidr" {
  description = "CIDR permitted to reach PostgreSQL from approved applications and developer tools. Do not use a broad internet CIDR."
  type        = string

  validation {
    condition     = !contains(["0.0.0.0/0", "::/0"], var.postgresql_client_cidr)
    error_message = "postgresql_client_cidr must not expose PostgreSQL to the internet."
  }
}

variable "postgresql_port" {
  description = "TCP port on which the instance-specific PostgreSQL service listens."
  type        = number
  default     = 5432

  validation {
    condition     = var.postgresql_port >= 1 && var.postgresql_port <= 65535 && floor(var.postgresql_port) == var.postgresql_port
    error_message = "postgresql_port must be an integer between 1 and 65535."
  }
}

variable "postgresql_major" {
  description = "PostgreSQL major version baked into image_ocid. A data volume cannot be attached to a different major without an explicit upgrade."
  type        = string
  default     = "18"

  validation {
    condition     = can(regex("^[0-9]+$", var.postgresql_major))
    error_message = "postgresql_major must contain only a major version number."
  }
}

variable "ocpus" {
  description = "OCPUs assigned to the PostgreSQL VM."
  type        = number
  default     = 2
}

variable "memory_in_gbs" {
  description = "Memory assigned to the PostgreSQL VM."
  type        = number
  default     = 16
}

variable "data_volume_size_gbs" {
  description = "Size of the stack-created persistent data volume. It is ignored when existing_data_volume_id is supplied."
  type        = number
  default     = 200

  validation {
    condition     = var.data_volume_size_gbs >= 50
    error_message = "OCI Block Volumes must be at least 50 GiB."
  }
}

variable "data_volume_vpus_per_gb" {
  description = "OCI Block Volume performance setting. Modify this value to test IOPS tiers without replacing the VM or database volume."
  type        = number
  default     = 10

  validation {
    condition     = floor(var.data_volume_vpus_per_gb) == var.data_volume_vpus_per_gb && (contains([0, 10, 20], var.data_volume_vpus_per_gb) || (var.data_volume_vpus_per_gb >= 30 && var.data_volume_vpus_per_gb <= 120))
    error_message = "Use OCI's supported VPU/GB values: 0, 10, 20, or an integer from 30 through 120."
  }
}

variable "data_volume_device" {
  description = "Consistent OCI paravirtualized device path used for the data-volume attachment and cloud-init mount."
  type        = string
  default     = "/dev/oracleoci/oraclevdb"

  validation {
    condition     = startswith(var.data_volume_device, "/dev/")
    error_message = "data_volume_device must be an absolute /dev path supported by the selected OCI VM shape."

}
}

variable "data_volume_mount_point" {
  description = "Mount point used only for the persistent PostgreSQL volume."
  type        = string
  default     = "/pgdata"

  validation {
    condition     = startswith(var.data_volume_mount_point, "/") && var.data_volume_mount_point != "/"
    error_message = "data_volume_mount_point must be an absolute path other than /."
  }
}

variable "data_volume_wait_seconds" {
  description = "How long first-boot cloud-init waits for Terraform's post-launch volume attachment."
  type        = number
  default     = 900

  validation {
    condition     = var.data_volume_wait_seconds >= 60 && floor(var.data_volume_wait_seconds) == var.data_volume_wait_seconds
    error_message = "data_volume_wait_seconds must be an integer of at least 60 seconds."
  }
}

variable "initialize_empty_data_volume" {
  description = "Format a blank volume as XFS and initialize a new cluster. Set false to fail safely if an unexpected blank volume is attached."
  type        = bool
  default     = true
}

variable "data_volume_encryption_in_transit_enabled" {
  description = "Enable OCI in-transit encryption for the paravirtualized data-volume attachment. Keep this constant across performance comparisons."
  type        = bool
  default     = true
}

variable "subnet_ocid" {
  type = string
}

variable "nsg_ocid" {
  type = string
}

variable "tls_mode" {
  description = "self-signed is convenient for isolated performance tests; provided requires a trusted certificate and key to exist before the service starts."
  type        = string
  default     = "self-signed"

  validation {
    condition     = contains(["self-signed", "provided"], var.tls_mode)
    error_message = "tls_mode must be self-signed or provided."
  }
}

variable "tls_cert_file" {
  description = "Absolute path of the TLS certificate used by PostgreSQL."
  type        = string
  default     = "/etc/postgresql-instance/tls/server.crt"
}

variable "tls_key_file" {
  description = "Absolute path of the TLS private key used by PostgreSQL."
  type        = string
  default     = "/etc/postgresql-instance/tls/server.key"
}
