#!/usr/bin/env bash
set -euo pipefail

: "${POSTGRESQL_MAJOR:?POSTGRESQL_MAJOR must be set}"

if ! [[ "${POSTGRESQL_MAJOR}" =~ ^[0-9]+$ ]]; then
  echo "POSTGRESQL_MAJOR must contain only a major version number." >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install --yes --no-install-recommends \
  "postgresql-${POSTGRESQL_MAJOR}" \
  "postgresql-client-${POSTGRESQL_MAJOR}" \
  "postgresql-contrib-${POSTGRESQL_MAJOR}" \
  ca-certificates \
  curl \
  dnsutils \
  git \
  jq \
  netcat-openbsd \
  unattended-upgrades \
  ufw

# Ubuntu's PostgreSQL packages create the service account named "postgres".
# Create the requested separate, non-login system account without changing the
# package-managed runtime account or its permissions.
if ! getent group postgresql >/dev/null; then
  groupadd --system postgresql
fi

if ! id postgresql >/dev/null 2>&1; then
  useradd \
    --system \
    --gid postgresql \
    --home-dir /var/lib/postgresql \
    --no-create-home \
    --shell /usr/sbin/nologin \
    postgresql
fi

install --directory --owner postgresql --group postgresql --mode 0750 /etc/postgresql-image

# The package creates a default cluster during installation. An image must not
# contain a shared database, credentials, WAL, or instance-specific pg_hba.conf,
# so remove every package-created cluster. cloud-init creates a fresh one later.
mapfile -t clusters < <(pg_lsclusters --no-header | awk '{print $1 ":" $2}')
for cluster in "${clusters[@]}"; do
  IFS=: read -r version name <<<"${cluster}"
  pg_dropcluster --stop "${version}" "${name}"
done

systemctl disable postgresql.service || true

cat >/etc/postgresql-image/README <<'EOF'
This is a generalized PostgreSQL image. It intentionally contains no cluster,
database, roles, passwords, TLS private key, pg_hba.conf, or application data.
Use the deployment cloud-init configuration to create and configure the cluster.
EOF
chmod 0644 /etc/postgresql-image/README
