```bash
export OCI_BOOTSTRAP_CMP_OCID=$(oci iam compartment create \
  --compartment-id $OCI_TENANCY \
  --description "Manually created by Admin in new tenancy." \
  --name "cmp-bootstrap" \
  --query data.id --raw-output)

export OCI_NAMESPACE=$(oci os ns get --query data --raw-output)

oci os bucket create --name "oci-lz-tfstate" \
  --compartment-id "$OCI_BOOTSTRAP_CMP_OCID" \
  --namespace-name "$OCI_NAMESPACE" \
  --public-access-type NoPublicAccess \
  --versioning Enabled \
  --region "$OCI_REGION"

export AUTH_USR=$(oci iam user create --name "automation_user" --description "User meant to run automations" --compartment-id "$OCI_TENANCY")

export ADMIN_GRP=$(oci iam group list --compartment-id "$OCI_TENANCY" --name "Administrators" --query 'data[0].id' --raw-output)

oci iam group add-user --group-id "$ADMIN_GRP" --user-id "$AUTH_USR"
```
