#!/usr/bin/env bash
set -euo pipefail

# The baked baseline permits no inbound traffic. The deployment cloud-init
# template adds only TCP/22 for administration and TCP/5432 for PostgreSQL from
# approved CIDRs. UFW's default rules continue to allow loopback and established
# return traffic; outbound access remains available for package and backup paths.
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw --force enable

wget -P /tmp https://raw.githubusercontent.com/oracle/oci-utils/master/libexec/oci-image-cleanup
chmod 700 /tmp/oci-image-cleanup
sudo /tmp/oci-image-cleanup -f
