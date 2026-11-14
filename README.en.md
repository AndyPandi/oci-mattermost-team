# OCI Mattermost Team

[한국어](README.md) · [English](README.en.md)

Deploy a Mattermost collaboration environment for OCI PoC participants to discuss work and share files. This supports collaboration during other PoCs; it is not a Mattermost evaluation offering or an official Oracle/Mattermost Marketplace product.

## Deploy to Oracle Cloud

[![Deploy to Oracle Cloud](https://oci-resourcemanager-plugin.plugins.oci.oraclecloud.com/latest/deploy-to-oracle-cloud.svg)](https://cloud.oracle.com/resourcemanager/stacks/create?zipUrl=https%3A%2F%2Fgithub.com%2FAndyPandi%2Foci-mattermost-team%2Farchive%2Frefs%2Fheads%2Fmain.zip)

**Public repository source import:** sign into OCI → confirm target region → import configuration → enter variables → review Plan → Apply. Clicking the button does not create resources; Apply incurs OCI resource costs.

Select the Console region first. Changing only the region variable may not refresh AD/VCN/subnet lists. This link uses the latest main ZIP; review changes before execution. The complete public-button flow has not yet been validated in Console.

If automatic import fails, use Code → Download ZIP, then Resource Manager → Create stack → My configuration to upload it. Select the working directory containing Terraform files and schema.yaml. Anonymous import cannot fetch a private repository; never embed tokens in URLs.

## Deployment steps

1. Import using the button and confirm region, compartment and working directory. A manual ZIP must include *.tf, schema.yaml, compose.yaml and cloud-init/. Exclude .terraform, state, actual tfvars and keys.
2. Choose Terraform 1.5+ and enter instance name, compartment/AD, x86_64 Flex shape, OCPU and RAM. Oracle Linux 9 and a 50 GiB boot volume are fixed. 1 OCPU/8 GiB is provisional, not a performance guarantee. ARM/A1 is excluded.
3. Upload/drop one SSH public .pub file or paste an OpenSSH public key. Keep the private key on your PC. Set a trusted source IPv4 CIDR /24–/32 (recommend your public IP/32); 0.0.0.0/0 is rejected. Choose a new VCN or an existing VCN/subnet in the selected compartment.
4. Choose ephemeral / reserved_new / none and automatic/manual private IP. Existing reserved IP adoption is unsupported. none requires an existing network with VPN/bastion access, DNS and internet egress. New private-only networks are rejected. Existing security lists combine with NSGs, so review them.
5. Run Plan and review resources, costs, image and changes to existing infrastructure. Apply only after review/authorization. Apply success is not application readiness.
6. SSH to the VM and check initialization:


```sh
sudo cloud-init status --wait
sudo systemctl status mattermost.service --no-pager
sudo docker compose -f /opt/mattermost/compose.yaml ps
sudo df -h / /srv/mattermost
curl -fsS http://127.0.0.1:8065/api/v4/system/ping
```

From your PC, open a tunnel:

```sh
ssh -i "<PRIVATE_KEY_PATH>" -N -L 127.0.0.1:8065:127.0.0.1:8065 opc@<ssh_host>
```

Keep the tunnel open and visit http://localhost:8065 to register the first administrator. Private-only deployments need VPN or an approved jump host first. Every participant needs an access path; this is not a public HTTPS website. HTTPS/Caddy is not implemented yet. After correcting bootstrap failures, an administrator can retry with sudo /usr/local/sbin/mattermost-bootstrap; existing DB credentials are retained.

## Existing stacks and region changes

- A Git push or downloaded ZIP does not update an existing stack. Upload the new configuration through Edit → Terraform configuration, or start a separate stack in the target Console region.
- Match Console and input region, then reselect compartment → AD → VCN → subnet. Chicago-to-Chuncheon automatic list refresh is not guaranteed. Do not proceed with stale selections.
- Changing the region of a deployed stack is not a migration feature. Review a new Plan for replacements/deletions; never blindly Apply saved variables.
- Native Compute-style SSH key generation/private-key download in Resource Manager is not confirmed by official documentation. Generate keys locally if needed and supply only the public key. This project does not generate private keys into Terraform state.
- [Control research and Console checks](docs/research/resource-manager-controls.md)

## Data, archives and safety

Mattermost Team Edition and PostgreSQL run through Docker Compose. Data is bind-mounted under /srv/mattermost on the boot filesystem; no additional Block Volume is created. OS, images, DB, files, logs and archive temporary copies share space. The 50 GiB block volume does not imply a 50 GiB root filesystem: inspect df and filesystem layout.

For end-of-PoC offline HTML and attachments, use the separate [Mattermost Archiver](https://github.com/AndyPandi/mattermost-archiver). It is not automatically installed by this stack and is not a complete backup/restore solution. DM/private-channel export requires separate authorization. Verify external copies and readability before deleting VM/boot storage.

Never commit private keys, real environment values, Terraform state or backups. Do not share env files, full docker inspect or resolved compose configuration containing secrets. Resource costs are the deployer's responsibility.

## Local checks

Terraform 1.7+ for mock tests (tested with 1.9.8), Python 3, PyYAML and jsonschema:

```sh
terraform init -backend=false
terraform fmt -check -recursive
terraform validate
terraform test
python3 tests/static_checks.py
```

These checks do not run OCI Apply; tests use mock providers. Official control-definition checks are not proof of Console rendering. Read the state document for evidence and outstanding checks, including networking, reboot/persistence and restore tests. Docker's RHEL9 installation procedure is used on Oracle Linux; do not infer certification from compatibility.

## Documentation

- [Current state and validation checklist](docs/project-state.md)
- [Architecture](docs/architecture/system-overview.md)
- [Deployment decision](docs/decisions/ADR-002-deployment-and-archive.md)
- [Upstream Compose research](docs/research/upstream-compose.md)
- [Documentation rules](docs/README.md)

## License

This repository's own distribution license has not been selected. Mattermost, PostgreSQL, Caddy and third-party components retain their respective licenses; upstream licenses do not automatically cover this entire repository. The separate archiver's MIT license does not license this repository.
