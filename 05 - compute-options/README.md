# Lab 5: Compare Flexible and Ampere Compute Options

## Introduction

Compute shape selection is a workload decision. OCI flexible shapes let you select CPU and memory within the shape family’s supported limits; OCI also offers Arm-based Ampere flexible shapes. This lab turns those choices into an explicit PostgreSQL compatibility and performance assessment rather than treating a shape as an immutable server size.

Keep the workload definition portable: use standard PostgreSQL backups, versioned schema migrations, open Terraform and Kubernetes formats, and multi-architecture packages or container images where needed. A compatible workload can be rebuilt on a new OCI shape or another approved target without copying a hand-maintained server.

Changing an instance shape can require a stop and can be constrained by capacity, image support, and architecture. Treat a shape change as a planned infrastructure change with a backup and a rollback path.

Estimated Time: 45 minutes

### Objectives

In this lab, you will:

- Inspect the current PostgreSQL VM’s shape and resource allocation.
- Define a repeatable x86 and Arm compatibility test.
- Compare flexible shape options without assuming cross-architecture equivalence.
- Validate that the PostgreSQL artifact and recovery procedure are portable across target architectures.

## Task 1: Capture the current VM profile

1. Query the current shape and allocated resources from Cloud Shell.

    ```bash
    oci compute instance get --instance-id "$INSTANCE_OCID" \
      --query 'data.{shape:shape,ocpus:\"shape-config\".ocpus,memory_gb:\"shape-config\".\"memory-in-gbs\",state:\"lifecycle-state\"}' \
      --output table
    ```

2. On the VM, collect PostgreSQL and operating-system facts.

    ```bash
    uname -m
    nproc
    free -h
    sudo -u postgres psql -c 'show shared_buffers;'
    sudo -u postgres psql -c 'show max_connections;'
    ```

3. Add the baseline to your change log. Include the PostgreSQL version, extension list, image architecture, data size, and the load profile you intend to test.

## Task 2: Define the flexible-shape decision

1. Create a decision record for an x86 flexible VM.

    | Decision input | Evidence to collect |
    | --- | --- |
    | CPU saturation | PostgreSQL workload CPU, query latency, and wait events |
    | Memory pressure | `shared_buffers`, cache hit ratio, host memory, and swap |
    | Network demand | Client traffic, replication traffic, and backup path |
    | Storage demand | IOPS, throughput, volume latency, and recovery targets |

2. Use the same Terraform module with a separate variable set for each candidate shape. Review `terraform plan` before any replacement or resize action.

3. Prefer a new test instance over modifying the production-like VM in place. Restore from a known backup or use a disposable PostgreSQL dataset so the test is reproducible.

## Task 3: Test Ampere compatibility

1. Create a second Terraform variable file for an Arm-based Ampere flexible shape, such as `VM.Standard.A1.Flex` or the currently available Ampere flexible family in your region.

2. Confirm that every component has an Arm64-compatible build.

    Check the Linux image, PostgreSQL packages, extensions, backup tools, monitoring agents, and any native client libraries. Container images must also provide a multi-architecture or Arm64 manifest.

3. Run the same schema, data volume, query mix, and backup/restore checks used for the x86 candidate.

    Build the candidate from the same versioned source definition. Restore data from a standard PostgreSQL backup; do not clone the existing boot disk across architectures.

4. Compare the results as a workload profile, not as a simple CPU-count comparison.

    Include throughput, p95 latency, cost model, operational tooling compatibility, and regional capacity. Use the selected architecture only after the compatibility results and recovery test meet the team’s acceptance criteria.

5. Publish the successful candidate as a new immutable release.

    Record the Git tag, image or container digest, architecture, Terraform variable set, PostgreSQL version, extension compatibility result, and backup-restore evidence. This record lets the team reproduce the tested deployment instead of treating the benchmark VM as a golden mutable server.

## Learn More

- [Arm-based compute](https://docs.oracle.com/en-us/iaas/Content/Compute/References/arm.htm)
- [Compute shapes](https://docs.oracle.com/en-us/iaas/Content/Compute/References/computeshapes.htm)

## Acknowledgements

* **Author** - Platform Engineering Workshop Team
* **Last Updated By/Date** - Codex / 2026-07-20
