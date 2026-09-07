# Workshop Details

## Short Description

An Azure-to-OCI workshop for platform engineers that deploys and operates PostgreSQL on OCI virtual machines and Kubernetes without console-driven infrastructure changes. It explores how immutable infrastructure improves repeatability, recovery, and controlled workload relocation.

## Long Description

Use PostgreSQL as a common workload to map Azure platform-engineering practices to OCI. First establish an OCI landing zone with the CCoE operating model in mind. Then create a Cloud Shell operations environment, provision a PostgreSQL VM through Terraform, and perform storage operations while the database remains available.

The final labs compare flexible x86 and ARM shapes, then deploy PostgreSQL to Oracle Container Engine for Kubernetes (OKE) and manage the application through a GitOps workflow. You will see how versioned definitions, replaceable compute, and externalized data support repeatable delivery, recovery, and deployment to compatible target environments. The workshop emphasizes identity boundaries, network design, immutable delivery, and operational verification.

## Workshop Outline

1. Introduction
2. Lab 1 - Establish an OCI Landing Zone Foundation
3. Lab 2 - Establish an Operations Workstation in Cloud Shell
4. Lab 3 - Deploy PostgreSQL on an OCI VM with Terraform
5. Lab 4 - Resize PostgreSQL Storage and Change Performance Online
6. Lab 5 - Compare Flexible and Ampere Compute Options
7. MultiCloud
