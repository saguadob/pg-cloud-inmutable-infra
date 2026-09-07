# Lab 1: Establish an OCI Landing Zone Foundation

## Introduction

An enterprise landing zone is the governed starting point for workload teams. It applies shared decisions about identity, network, security, logging, monitoring, budgets, and operating boundaries before teams deploy applications. The concepts will be familiar to engineers who have built Azure landing zones: guardrails are centralized, workload teams receive defined boundaries, and infrastructure is delivered as code.

OCI Cloud Adoption Framework (CAF) gives this work a structured model across business strategy, people strategy, security, process design, technology implementation, and management and operations. It complements—not replaces—an enterprise's existing cloud strategy. A Cloud Center of Excellence (CCoE) can retain common governance practices across providers while adopting OCI-specific controls and patterns.

OCI Landing Zones turn the CAF foundation into prescriptive Terraform blueprints. The templates make many baseline choices for you, but they do not remove accountability: the CCoE must still select a topology, CIDRs, identity integration, operating model, and service ownership that fit the enterprise.

Estimated Time: 45 minutes

### Objectives

In this lab, you will:

- Map OCI CAF and landing-zone concepts to an enterprise CCoE operating model.
- Choose between the OCI Core Landing Zone and the OCI Operating Entities Landing Zone.
- Prepare the decisions and inputs required to deploy the selected Terraform blueprint.
- Create and review a Terraform plan before applying the landing zone.
- Establish a versioned, immutable delivery path for the landing-zone configuration.

## Task 1: Map your existing cloud governance to OCI

1. List the controls your CCoE already owns in Azure or another cloud.

    Start with identity federation, account or subscription hierarchy, network hubs, logging, security monitoring, cost governance, and workload onboarding. Keep the control intent common across clouds; map the implementation to the services and policy model of each provider.

2. Map the governance intent to OCI primitives.

    | Governance concern | Typical Azure concept | OCI landing-zone implementation |
    | --- | --- | --- |
    | Resource organization | Management groups and subscriptions | Tenancy and compartment hierarchy |
    | Delegated access | Entra ID groups and Azure RBAC | Identity domains, groups, dynamic groups, and IAM policies |
    | Network foundation | Hub-and-spoke virtual networks | Hub VCN, spoke VCNs, DRG, gateways, and NSGs |
    | Security baseline | Policy, Defender, and centralized logs | Cloud Guard, Security Zones, Vault, logging, scanning, and alarms |
    | Cost control | Budgets, tags, and cost-management views | Budgets, tagging, quotas, and cost reports |

3. Record the OCI-specific decisions that need an owner.

    Decide who owns tenancy administration, compartment lifecycle, IAM policy review, CIDR allocation, network connectivity, security incident response, and workload onboarding. A landing zone accelerates implementation; it does not decide the enterprise operating model for you.


## Task 2: Select the landing-zone blueprint

1. Compare the two current choices for this workshop.

    | Choose | When it fits | Delivery model |
    | --- | --- | --- |
    | OCI Core Landing Zone | You want a standardized, centralized tenancy foundation with common enterprise services, CIS-aligned controls, and optional hub-and-spoke, OKE, or three-tier networks. | One integrated Terraform blueprint, deployable through OCI Resource Manager or from source. |
    | OCI Operating Entities Landing Zone | You need to onboard functional divisions or operating entities with separate, independently managed stacks while retaining shared design guidance and governance patterns. | Multiple declarative IaC blueprints and open assets for the central and operating-entity layers. |

2. Do not select the retired Oracle Enterprise Landing Zone (OELZ) for a new deployment.

    OCI Core Landing Zone unifies the earlier CIS Landing Zone and OELZ initiatives into the current standardized solution. In this workshop, “OE landing zone” means the OCI Operating Entities Landing Zone, not the deprecated Oracle Enterprise Landing Zone.

3. Choose the Core Landing Zone if the workshop tenancy needs a single central foundation. Choose the Operating Entities Landing Zone if the exercise must model a central platform team and multiple business or functional divisions.

## Learn More

- [OCI Cloud Adoption Framework](https://docs.oracle.com/en-us/iaas/Content/cloud-adoption-framework/home.htm)
- [OCI Landing Zones overview](https://docs.oracle.com/en-us/iaas/Content/cloud-adoption-framework/oci-landing-zones-overview.htm)
- [OCI Core Landing Zone](https://docs.oracle.com/en-us/iaas/Content/cloud-adoption-framework/oci-core-landing-zone.htm)
- [OCI multicloud strategy](https://docs.oracle.com/en-us/iaas/Content/multicloud/Oraclemulticloud.htm)
