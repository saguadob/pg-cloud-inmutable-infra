# PostgreSQL immutable-image build

This Packer configuration builds an OCI custom image from a pinned Ubuntu image
OCID. It contains a selected PostgreSQL major version plus `pgbench`, `fio`,
`iostat`, XFS, and multipath support, but intentionally contains no cluster,
database data, SSH host keys, machine ID, cloud-init state, or Packer SSH key.

The `postgresql` Linux account is a non-login image/automation account. Ubuntu's
package-managed `postgres` account remains the account that runs PostgreSQL.

## Build

1. Use a dedicated build subnet and NSG. It needs outbound package access and
   SSH only from the Packer runner. Packer's temporary VM must be reachable on
   TCP/22 while it provisions the image.
2. Copy `postgresql.pkrvars.hcl.example` to `postgresql.pkrvars.hcl`, supply a
   pinned Ubuntu image OCID, and choose the PostgreSQL major version available
   in that image's approved package repositories.
3. Build the image:

   ```bash
   packer init .
   packer fmt -check .
   packer validate -var-file=postgresql.pkrvars.hcl .
   packer build -var-file=postgresql.pkrvars.hcl .
   ```

Pass the resulting custom image OCID as `image_ocid` to
`../files/terraform`. That deployment renders `postgresql-instance.yaml` into
OCI instance metadata. It initializes an empty data volume once and, on a
later VM replacement, recognizes the existing `PGDATA` directory and starts it
without copying, formatting, or recreating the database.

Use `fio` only on a separate disposable volume. `pgbench` is the appropriate
benchmark against this image's persistent PostgreSQL data volume.
