#!/bin/bash
# No credentials in cloud-init, Terraform, shell tracing, or command arguments.
set -euo pipefail
umask 077
source /etc/os-release
[[ "$ID" == ol && "$VERSION_ID" == 9* && "$(uname -m)" == x86_64 ]] || { echo 'Oracle Linux 9 x86_64 required' >&2; exit 1; }
install -d -m 0700 /opt/mattermost
install -d -m 0755 /srv/mattermost
exec 9>/opt/mattermost/bootstrap.lock
flock -n 9 || exit 1
[[ $(df -Pk /srv/mattermost | awk 'NR==2 {print $4}') -ge 12582912 ]] || { echo 'Insufficient boot filesystem space (12 GiB required)' >&2; exit 1; }
retry() {
  local attempt
  for attempt in {1..12}; do
    if "$@"; then return 0; fi
    sleep 30
  done
  return 1
}
# Docker documents RHEL 9, not Oracle Linux certification: see research caveat.
# Do not remove existing packages or replace daemon/firewall configuration.
retry dnf -y install dnf-plugins-core openssl python3 gnupg2
if [[ ! -f /etc/yum.repos.d/docker-ce.repo ]]; then
  retry dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
fi
key=$(mktemp)
trap 'rm -f "$key"' EXIT
retry curl -fsSL https://download.docker.com/linux/rhel/gpg -o "$key"
fingerprint=$(gpg --batch --show-keys --with-colons "$key" | awk -F: '$1=="fpr" {print $10; exit}')
[[ "$fingerprint" == 060A61C51B558A7F742B77AAC52FEB6B621E9F35 ]] || { echo 'Docker signing key mismatch' >&2; exit 1; }
rpm --import "$key"
retry dnf -y --releasever=9 install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin container-selinux
# SELinux remains enforcing; enable Docker label separation without replacing daemon settings.
python3 - <<'CONFIG'
import json, pathlib
p = pathlib.Path("/etc/docker/daemon.json")
p.parent.mkdir(parents=True, exist_ok=True)
config = json.loads(p.read_text()) if p.exists() else {}
if config.get("selinux-enabled") is False:
    raise SystemExit("Existing daemon disables SELinux; review manually")
config["selinux-enabled"] = True
tmp = p.with_suffix(".json.tmp")
tmp.write_text(json.dumps(config) + chr(10))
tmp.chmod(0o600)
tmp.replace(p)
CONFIG
systemctl enable docker
systemctl restart docker
# Docker is root-equivalent: do not add opc to docker group.
for path in config files logs plugins client-plugins bleve-indexes; do
  install -d -o 2000 -g 2000 -m 0750 "/srv/mattermost/$path"
done
install -d -m 0700 /srv/mattermost/postgres
python3 - <<'PY'
import os, pathlib, secrets
p = pathlib.Path('/opt/mattermost')
data = pathlib.Path('/srv/mattermost/postgres')
names = ('db-password', 'db-admin-password')
# Refuse legacy/partial installations before changing credentials or env files.
if any(data.iterdir()) and not all((p / name).is_file() for name in names):
    raise SystemExit('Existing DB lacks split credentials; see SECURITY.md. No automatic migration')
passwords = {}
for name in names:
    secret = p / name
    if secret.is_symlink():
        raise SystemExit('Secret symlink refused')
    if secret.exists():
        value = secret.read_text().strip()
        if len(value) != 64 or any(c not in '0123456789abcdef' for c in value):
            raise SystemExit('Invalid canonical secret; manual recovery required')
        passwords[name] = value
for name in names:
    secret = p / name
    if name not in passwords:
        passwords[name] = secrets.token_hex(32)
        fd = os.open(secret, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
        with os.fdopen(fd, 'w') as f:
            f.write(passwords[name])
    secret.chmod(0o600)
password = passwords['db-password']
admin = passwords['db-admin-password']
if password == admin:
    raise SystemExit('Admin and application secrets must differ')
files = {
    'postgres.env': f'POSTGRES_USER=mmadmin\nPOSTGRES_DB=postgres\nPOSTGRES_PASSWORD={admin}\nMM_APP_PASSWORD={password}\n',
    'mattermost.env': f'MM_SQLSETTINGS_DATASOURCE=postgres://mmuser:{password}@postgres:5432/mattermost?sslmode=disable&connect_timeout=10\n'
}
for name, content in files.items():
    tmp = p / (name + '.tmp')
    fd = os.open(tmp, os.O_WRONLY | os.O_CREAT | os.O_TRUNC | os.O_NOFOLLOW, 0o600)
    with os.fdopen(fd, 'w') as f:
        os.fchmod(f.fileno(), 0o600)
        f.write(content)
    tmp.replace(p / name)
PY
unit=$(mktemp)
cat > "$unit" <<'UNIT'
[Unit]
Description=Mattermost SSH-tunnel collaboration
Requires=docker.service
After=docker.service network-online.target
Wants=network-online.target
StartLimitIntervalSec=0
[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/mattermost
ExecStart=/usr/bin/docker compose up -d --wait --wait-timeout 600
ExecStop=/usr/bin/docker compose stop
TimeoutStartSec=900
Restart=on-failure
RestartSec=30
[Install]
WantedBy=multi-user.target
UNIT
if [[ -f /etc/systemd/system/mattermost.service ]] && ! cmp -s "$unit" /etc/systemd/system/mattermost.service; then
  rm -f "$unit"
  echo 'Existing mattermost.service differs; review manually' >&2; exit 1
fi
install -m 0644 "$unit" /etc/systemd/system/mattermost.service
rm -f "$unit"
cd /opt/mattermost
retry docker compose pull
systemctl daemon-reload
systemctl enable --now mattermost.service
echo 'Mattermost containers healthy; connect through SSH tunnel and register administrator.'
