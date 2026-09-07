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
    git clone https://github.com/saguadob/pg-cloud-inmutable-infra.git
    ```
    and change your working directory to `~/"pg-cloud-inmutable-infra/03 - postgresql-on-vm"`

2. Packer has a limitation with the cloud shell. Create your own API key as you would with your local machine
    ```bash
    oci setup keys --key-name packer_cli
    oci setup repair-file-permissions --file ~/.oci/packer_cli.pem 
    oci setup repair-file-permissions --file ~/.oci/packer_cli_public.pem
    oci iam user api-key upload --user-id $OCI_CS_USER_OCID --key-file ~/.oci/packer_cli_public.pem                                                         
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

5. Init, Validate and Build Imae:

    ```bash
    packer init .
    packer validate -var-file=pg.pkrvars.hcl .
    packer build -var-file=pg.pkrvars.hcl .
    ```

## Task 2: Plan and apply the VM deployment

1. Save the OCID of the generated image. and update the `example.auto.tfvars`to `lab.auto.tfvars`.

2. Generate a shh key pair to be able to ssh form the CloudShell to the PG server:
    ```bash
    ssh-keygen -t rsa -N "" -b 2048 -C "pg_vm"
    ```

3. Initialize the providers and format the configuration.

    ```bash
    terraform init
    terraform fmt -recursive
    terraform validate
    ```

4. Review the plan before creating any resources.

    ```bash
    terraform plan -out tfplan
    ```

5. Apply the reviewed plan.

    ```bash
    terraform apply tfplan
    ```

## Task 3: Verify PostgreSQL without changing the desired state

1. Connect through your approved private access path. If using OCI Bastion, create the managed SSH session according to your organization’s policy, then connect to the private IP.

    ```bash
    ssh -i ~/.ssh/id_rsa ubuntu@<replace_me>
    ```

2. On the VM, check the PostgreSQL service and data mount.

    ```bash
    sudo systemctl is-active postgresql-instance.service
    findmnt /pgdata
    sudo -u postgres psql -d postgres -c 'select version();'
    ```



## Learn More

- [Terraform provider for OCI](https://registry.terraform.io/providers/oracle/oci/latest/docs)
- [Compute instances](https://docs.oracle.com/en-us/iaas/Content/Compute/Concepts/computeoverview.htm)

## Acknowledgements

* **Author** - Platform Engineering Workshop Team
* **Last Updated By/Date** - Codex / 2026-07-20
