# Lab 4: Resize PostgreSQL Storage and Change Performance Online

## Introduction

PostgreSQL capacity and I/O demand change over time. OCI block volumes can be expanded while attached, and their performance setting can be changed after creation. This lab changes both controls while PostgreSQL remains online, then extends the Linux filesystem and verifies that the database continues to answer queries.

The online operation is a controlled exception to the immutable compute pattern. Record it as a versioned infrastructure change, update the declarative configuration, and test a replacement build from the revised definition. Do not let a successful emergency change become undocumented drift.

This is an operational exercise, not a substitute for capacity planning. Test the full workload, backup and recovery objectives, application timeouts, and filesystem procedure before applying the pattern in production.

Estimated Time: 45 minutes

### Objectives

In this lab, you will:

- Capture a PostgreSQL availability baseline.
- Increase an attached block volume’s capacity through the OCI CLI.
- Change the volume performance setting.
- Rescan and grow the Linux storage stack without stopping PostgreSQL.
- Reconcile the storage change into the deployment definition and recovery evidence.

## Task 1: Record a baseline

1. In Cloud Shell, load the IDs that Terraform produced.

    ```bash
    export INSTANCE_OCID="$(cat "$HOME/$WORKSHOP_PREFIX/ops/instance-ocid")"
    export VOLUME_OCID="$(cat "$HOME/$WORKSHOP_PREFIX/ops/volume-ocid")"
    oci bv volume get --volume-id "$VOLUME_OCID" \
      --query 'data.{size_gb:\"size-in-gbs\",vpus:\"vpus-per-gb\",state:\"lifecycle-state\"}' --output table
    ```

2. On the PostgreSQL VM, start a simple availability probe in one terminal.

    ```bash
    while true; do
      date -Iseconds
      sudo -u postgres psql -tAc 'select now();' || exit 1
      sleep 5
    done
    ```

3. In a second terminal, identify the filesystem and block device that back `/var/lib/postgresql`.

    ```bash
    findmnt -no SOURCE,FSTYPE,SIZE,AVAIL /var/lib/postgresql
    lsblk -f
    ```

## Task 2: Expand the OCI block volume

1. Choose a new value greater than the current volume size. This example grows the volume to 100 GiB.

    ```bash
    oci bv volume update --volume-id "$VOLUME_OCID" --size-in-gbs 100 --wait-for-state AVAILABLE
    ```

2. Confirm that OCI reports the new capacity before changing the operating system.

    ```bash
    oci bv volume get --volume-id "$VOLUME_OCID" \
      --query 'data.{size_gb:\"size-in-gbs\",state:\"lifecycle-state\"}' --output table
    ```

3. Confirm that the availability probe did not stop and that the filesystem has the expected additional capacity.

4. Update the Terraform variable or module input that defines the volume size, commit the change, and attach the plan output to the change record.

    The running volume can grow online, but the source configuration must now describe the new desired capacity. A future replacement or recovery environment must not recreate the older volume size by accident.

## Task 3: Change block-volume performance

1. Set a performance level that is appropriate for a short test. This example updates the volume to 20 VPUs per GB.

    ```bash
    oci bv volume update --volume-id "$VOLUME_OCID" --vpus-per-gb 20 --wait-for-state AVAILABLE
    ```

2. Confirm the applied value.

    ```bash
    oci bv volume get --volume-id "$VOLUME_OCID" \
      --query 'data.{vpus:\"vpus-per-gb\",state:\"lifecycle-state\"}' --output table
    ```

3. Run a representative benchmark or a controlled query load, then record latency, throughput, and database behavior.

    ```bash
    # create benchmark test DB
    sudo -u postgres createdb pgbench
    sudo -u postgres pgbench -i -s 1000 pgbench
    # run benchmark for write operations 900 seconds
    sudo -u postgres pgbench -c 16 -j 4 -T 900 -P 30 -r -L 50 pgbench
    # run benchmark for read operations 900 seconds
    sudo -u postgres pgbench -b select-only -c 64 -j 8 -T 900 -P 30 -r pgbench
    ```

4. Commit the new performance setting and update the recovery runbook.

    Capture the OCI volume ID, volume size, performance setting, filesystem expansion procedure, backup reference, and validation result. Then create a disposable replacement from the revised configuration and confirm it can restore the PostgreSQL backup.

## Learn More

- [Online resizing of block and boot volumes](https://docs.oracle.com/en-us/iaas/Content/Block/Tasks/update-online-resize-block-boot-volume.htm)
- [Block volume performance](https://docs.oracle.com/en-us/iaas/Content/Block/Concepts/blockvolumeperformance.htm)
