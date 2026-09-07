# Immutable PostgreSQL benchmark VM

This Terraform definition deploys a VM from the PostgreSQL Packer image and
attaches a **persistent OCI Block Volume** for `PGDATA`. The boot disk is
disposable. Cloud-init waits for the attachment, formats an empty volume as XFS
only on its first use, creates the cluster there, and starts the same cluster
when a compatible replacement VM reattaches the volume.

The image provides `pgbench`, `fio`, `iostat`, and multipath tooling. `fio`
must run only against a separate disposable scratch volume: never run it on the
attached PostgreSQL data volume while PostgreSQL is using it.

## Initial deployment

1. Build the image in `../../packer` and record its custom image OCID.
2. Copy `terraform.tfvars.example` to `terraform.tfvars`, set the image OCID,
   tenancy values, precise SSH and PostgreSQL client CIDRs, and the intended
   volume size and VPU/GB setting.
3. Apply normally:

   ```bash
   terraform init
   terraform fmt -recursive
   terraform validate
   terraform plan -out tfplan
   terraform apply tfplan
   ```

The initial run creates an XFS volume, initializes the PostgreSQL cluster at
`/pgdata/postgresql/<major>/main`, and protects the volume from an ordinary
`terraform destroy`. Record `terraform output -raw data_volume_id` immediately.

## Replace the VM without replacing its database

Change `image_ocid` to a compatible newly built Packer image, then run the
normal reviewed `terraform plan` and `terraform apply`. Terraform fingerprints
both the image and rendered cloud-init, so a changed image or bootstrap policy
replaces the instance. It uses serial replacement: it detaches the volume,
destroys the old VM, creates the new VM, then reattaches the same volume.

You can also explicitly prove the path without changing a variable:

```bash
terraform apply -replace=oci_core_instance.postgresql
```

Never enable create-before-destroy for this database instance and never attach
the data volume as a writable filesystem to two VMs. OCI requires a clustered
filesystem for simultaneous read/write attachments; PostgreSQL on XFS is not
such a filesystem.

The PostgreSQL major version of the image must match `PG_VERSION` on the data
volume. Perform a documented major upgrade, dump/restore, or logical migration
instead of attaching a version-16 data directory to a version-17 image.

## Change only the storage performance tier

`data_volume_vpus_per_gb` is deliberately excluded from the VM replacement
fingerprint. Changing it from `10` to `20`, or to a supported Ultra High
Performance value, updates the same managed Block Volume in place. Review and
apply that small Terraform plan, wait for OCI to finish the volume update, and
then run the benchmark with the same VM, data, and application configuration.

For an independent deployment stack, set `existing_data_volume_id` to the saved
volume OCID. This stack then attaches that existing volume rather than creating
or owning one. The volume and VM must be in the same availability domain.

## First-boot TLS mode

`tls_mode = "self-signed"` is the usable default for an isolated benchmark
environment. It generates a new short-lived certificate per VM; use
`sslmode=require` for benchmark clients. It is not a production trust model.

For production, use `tls_mode = "provided"` and retrieve a trusted certificate
and key—such as through OCI Vault and instance principals—before the cloud-init
`runcmd` phase. Do not put passwords or private keys in OCI instance metadata.

## Expected checks

After each deployment or replacement:

```bash
sudo systemctl is-active postgresql-instance.service
findmnt /pgdata
sudo -u postgres psql -c 'show data_directory; show port;'
sudo -u postgres psql -c 'select version();'
```

For an Ultra High Performance volume, confirm that OCI enabled the attachment
for multipath before interpreting benchmark results. Keep the VM shape, OCPU,
memory, volume size, attachment settings, PostgreSQL configuration, and client
location fixed when comparing VPU levels.
