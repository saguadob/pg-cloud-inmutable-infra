# Lab 3: Deploy PostgreSQL on an OCI VM with Terraform

## Introduction

In this lab, Terraform creates the network and compute controls for a PostgreSQL VM. The design keeps PostgreSQL on a private subnet and grants access only through an approved source network security group (NSG). The database installation is bootstrapped with cloud-init, so the instance is reproducible rather than configured through console clicks.

Treat the VM as replaceable. Terraform, image selection, cloud-init, package versions, and PostgreSQL bootstrap commands define the compute artifact. Keep database data and backups on managed storage with a documented restore path. When the definition changes, build and verify a replacement rather than repairing configuration by hand on the running VM.

Estimated Time: 55 minutes

### Objectives

In this lab, you will:

- Apply Terraform to provision a VCN, private subnet, NSG, VM, and block volume.
- Install PostgreSQL through instance metadata.
- Verify that the database is running and that network exposure is limited.
- Create a versioned deployment record that can rebuild the VM in another approved environment.

## Task 1: Create a postgresql base image using Packer

1. Clone the repo witth the contents of this lab.

    ```bash
    gh repo clone saguadob/pg-cloud-inmutable-infra
    ```

2. Packer has a limitation with the cloud shell. Create your own API key as you would with your local machine
    ```bash
    oci setup keys --key-name packer_cli
    oci setup repair-file-permissions --file ~/.oci/packer_cli.pem 
    oci setup repair-file-permissions --file ~/.oci/packer_cli_public.pem
    ```

3. Modify the environment vairables to use as inputs for packer

    ```bash
    export PKR_VAR_oci_region="$OCI_REGION"
    export PKR_VAR_oci_tenancy_ocid="$OCI_TENANCY"
    export PKR_VAR_oci_user_ocid="$OCI_CS_USER_OCID"
    export PKR_VAR_oci_key_file="$HOME/.oci/packer_cli.pem"
    export PKR_VAR_oci_fingerprint="<replace_me>"
    export PKR_VAR_compartment_ocid="$OCI_LZ_PROJECT_CMP_OCID"

    export TF_VAR_compartment_ocid="$OCI_LZ_PROJECT_CMP_OCID"
    ```
4. Rename the `example.pkrvars.hcl` to `pg.pkrvars.hcl` and change with the appropiate values

3. Set a private, non-overlapping VCN CIDR and the CIDR permitted to administer PostgreSQL.

    The example permits PostgreSQL only from `admin_cidr`. In a production design, prefer a private application subnet or an NSG-to-NSG rule over a broad CIDR.

4. Pin and record the deployable inputs.

    Pin the Terraform provider version, Linux image OCID, and package repository policy. Commit the configuration and `terraform.lock.hcl`. Do not rely on the latest image or package being identical at a later date.

## Task 2: Plan and apply the VM deployment

1. Initialize the providers and format the configuration.

    ```bash
    terraform init
    terraform fmt -recursive
    terraform validate
    ```

2. Review the plan before creating any resources.

    ```bash
    terraform plan -out tfplan
    ```

3. Apply the reviewed plan.

    ```bash
    terraform apply tfplan
    ```

4. Record the instance and volume IDs for the next lab.

    ```bash
    terraform output -raw instance_id | tee "$HOME/$WORKSHOP_PREFIX/ops/instance-ocid"
    terraform output -raw data_volume_id | tee "$HOME/$WORKSHOP_PREFIX/ops/volume-ocid"
    terraform output -raw private_ip
    ```

5. Tag the reviewed deployment definition.

    ```bash
    git add infra/terraform
    git commit -m "Deploy PostgreSQL VM definition"
    git tag "pg-vm-$(date +%Y%m%d%H%M%S)"
    git rev-parse --short HEAD | tee "$HOME/$WORKSHOP_PREFIX/evidence/pg-vm-release.txt"
    ```

## Task 3: Verify PostgreSQL without changing the desired state

1. Connect through your approved private access path. If using OCI Bastion, create the managed SSH session according to your organization’s policy, then connect to the private IP.

2. On the VM, check the PostgreSQL service and data mount.

    ```bash
    sudo systemctl is-active postgresql
    sudo -u postgres psql -c 'select version();'
    findmnt /var/lib/postgresql
    ```

3. Create a small workload marker.

    ```bash
    sudo -u postgres psql <<'SQL'
    CREATE TABLE IF NOT EXISTS workshop_probe (
      id bigint generated always as identity primary key,
      captured_at timestamptz not null default now()
    );
    INSERT INTO workshop_probe DEFAULT VALUES;
    SELECT count(*) AS rows_written FROM workshop_probe;
    SQL
    ```

4. Capture the result in your change log.

    The database should be reachable only from the approved management or application path. A successful local `psql` check does not prove that an internet-facing route is safe; inspect the subnet route table and NSG rules as part of the review.

5. Prove the replacement path before treating the VM as resilient.

    Create a backup, restore it to a separately named test instance built from the same Git tag, and run the probe query there. Do not promote the test instance until schema, data, connectivity, and recovery checks pass. This makes the deployment definition—not the original VM—the recoverable unit.

## Learn More

- [Terraform provider for OCI](https://registry.terraform.io/providers/oracle/oci/latest/docs)
- [Compute instances](https://docs.oracle.com/en-us/iaas/Content/Compute/Concepts/computeoverview.htm)

## Acknowledgements

* **Author** - Platform Engineering Workshop Team
* **Last Updated By/Date** - Codex / 2026-07-20
