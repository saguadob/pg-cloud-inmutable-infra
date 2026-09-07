# Lab 2: Establish an Operations Workstation in Cloud Shell

## Introduction

Cloud Shell is a browser-based Oracle Linux environment with a pre-authenticated OCI CLI. Use it as a short-lived, auditable operations workstation rather than storing long-lived credentials on an engineer laptop. This lab sets the tenancy context, verifies permissions, and creates a small repository structure for infrastructure and operations artifacts. Cloud Shell is a control point, not the source of truth: publish every durable definition to Git.

Estimated Time: 35 minutes

### Objectives

In this lab, you will:

- Verify the active OCI CLI identity, region, tenancy, and compartment.
- Create a workspace for infrastructure and operational evidence.
- Define guardrails for identity and network access before provisioning PostgreSQL.
- Create a versioned workspace for immutable workload definitions and deployment evidence.

## Task 1: Open Cloud Shell and verify the OCI context

1. In the OCI Console, open Cloud Shell. Wait until the shell prompt is available.  
  > [!TIP]
  > Use the a direct link to the [OCI Cloud Shell in your tenancy](https://cloud.oracle.com/?tenant=livelabws&provider=extc&region=eu-stockholm-1&cloudshell=true&bdcstate=maximized). The raw URL is `https://cloud.oracle.com/?tenant=livelabws&provider=extc&region=eu-stockholm-1&cloudshell=true&bdcstate=maximized`.
  
  Close the ARM info. An OCI Cloud Shell tutorial will shoup, follow the tutorial and then type `Y`.

2. Install extra utilities using configuration as code.  
  Using single binary tools you can improve your cloudshell experience and accomodate to your operating model. 
  ```bash
  DOTFILES_REPO="https://github.com/saguadob/ephimeral-shell-dotfiles.git"
  source <(curl -fsSL "https://gist.github.com/saguadob/7212b97c605245091b73c9adba4d3af9/raw/bootstrap-ephimeral-cloud-shell.sh")
  ```
  This small script uses Chezmoi will copy a set of personalconfiguration files and Mise to install tools not included in the OCI Cloud Shell.

4. Open the code editor Set explicit shell variables for the workshop. Replace the placeholder values with your tenancy values.
    > [!TIP]
    > Use the a direct link to the [OCI Cloud Editor](https://cloud.oracle.com/?tenant=lzdevelopment&provider=Default&region=eu-stockholm-1&cloudshell=true&bdcstate=maximized&codeeditor=true). The raw URL is `https://cloud.oracle.com/?bdcstate=maximized&codeeditor=true`.  
    > You can use URL Query strings to create direct URLs to where you want to navigate in thee Cloud Console  
    > `https://cloud.oracle.com/identity/compartments/ocid1.compartment.oc1..aaaaaaaarzrmpjintb7padh3bndkuumjmlmie4sneaml6njenalmc5yv7kra?`  
    > `https://cloud.oracle.com?compartmentId=ocid1.compartment.oc1..aaaaaaaam5toiqdgnfjktfgzdgjxdho4pqfzmz2vauvlyc2nkrdv4ja4jrda`

    Change the file `~/.config/shell/aliases.sh`
    ```bash
    export OCI_LZ_PROJECT_CMP_OCID="<replace_me>"
    export OCI_NAMESPACE="<replace_me>"
    export OCI_LZ_PROJECT_VCN_OCID="<replacee_me>"
    ```

    Source the file, so the variables get reflected in the current session. When you open the cloud shell in a new tab, the `$PATH` and you environment variables will be applied in the session.  
    `$ source ~/.config/shell/aliases.sh`

5. Verify that your principal can list the compartment where we are going to deploy our workload as project member.

    ```bash
    oci iam compartment get --compartment-id "$OCI_LZ_PROJECT_CMP_OCID" \
      --query 'data.{name:name,id:id,lifecycle:"lifecycle-state"}' | jq
    ```

## Task 2: Define access and network guardrails

1. In the :arrow_upper_left: upper leeftt corner of the Cloud Shell, navigate to  
  `Network -> Private Network Definition List --> Create Private Network Definiton`
2. Create a Definiton using the values  
    - Compartment: `cmp-lz-lab-network` | VCN: `vcn-arn-lz-lab-projects`
    - Compartment: `cmp-lz-lab-network` | Subnet: `sn-arn-lz-lab-infra`
    - Compartment: `cmp-lz-lab-network` | NSG: `nsg-arn-lz-lab-infra`
3. Set as active network definition, create it and set it as the default network definition.

## Next steps
Proceed to Lab 3 to deeploy a Postgreswl workload.

## Learn More

- [Cloud Shell](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/cloudshellintro.htm)
- [OCI CLI concepts](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/cliconcepts.htm)
