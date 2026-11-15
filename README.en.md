# OCI Mattermost Team

[한국어](README.md) · [English](README.en.md)

Deploy Mattermost Team Edition on OCI for team conversations and file sharing with a repeatable deployment configuration. This is not an official Oracle/Mattermost Marketplace product.

## Deploy to Oracle Cloud

[![Deploy to Oracle Cloud](https://oci-resourcemanager-plugin.plugins.oci.oraclecloud.com/latest/deploy-to-oracle-cloud.svg)](https://cloud.oracle.com/resourcemanager/stacks/create?zipUrl=https%3A%2F%2Fgithub.com%2FAndyPandi%2Foci-mattermost-team%2Farchive%2Frefs%2Fheads%2Fmain.zip)

**Public repository source import:** sign into OCI → confirm target region → import configuration → enter variables → review Plan → Apply. Clicking the button does not create resources; Apply incurs OCI resource costs.

Select the Console region first. Changing only the region variable may not refresh AD/VCN/subnet lists. This link uses the latest main ZIP; review changes before execution. The complete public-button flow has not yet been validated in Console.

If automatic import fails, use Code → Download ZIP, then Resource Manager → Create stack → My configuration to upload it. Select the working directory containing Terraform files and schema.yaml. Anonymous import cannot fetch a private repository; never embed tokens in URLs.

## Deployment steps

1. Import using the button and confirm region, compartment and working directory. A manual ZIP must include *.tf, schema.yaml, compose.yaml and cloud-init/. Exclude .terraform, state, actual tfvars and keys.
2. Choose Terraform 1.5+ and enter instance name, compartment/AD, x86_64 Flex shape, OCPU and RAM. Oracle Linux 9 and a 50 GiB boot volume are fixed. 1 OCPU/8 GiB is provisional, not a performance guarantee. ARM/A1 is excluded.
3. Upload/drop one SSH public .pub file or paste an OpenSSH public key. Keep the private key on your PC. Set an IPv4 CIDR /0–/32 (recommend your administrator public IP/32). `0.0.0.0/0` is accepted but opens TCP 22 to all IPv4; SSH key authentication is still required. Access is not automatically closed after install. Afterwards, narrow `ssh_ingress_cidr` in the stack variables (recommend /32), review Plan, then Apply. Choose a new VCN or an existing VCN/subnet in the selected compartment.
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

Keep the tunnel open and visit http://localhost:8065 to register the first administrator. Private-only deployments need VPN or an approved jump host first. Every participant needs an access path; this is not a public HTTPS website. HTTPS/Caddy is not implemented yet. After correcting bootstrap failures, an administrator can retry with sudo /usr/local/sbin/mattermost-bootstrap; split-role DB credentials are retained; legacy installations require the explicit maintenance procedure in [SECURITY.md](SECURITY.md), not an automatic migration.

## Existing stacks and region changes

- The new-deployment name default is `mattermost`. Explicitly retain your existing `instance_name` when updating a stack; changing it can rename resource display names. Internal network DNS labels are retained for compatibility. Do not replace an existing VCN/subnet just to adopt new naming.

- A Git push or downloaded ZIP does not update an existing stack. Upload the new configuration through Edit → Terraform configuration, or start a separate stack in the target Console region.
- Match Console and input region, then reselect compartment → AD → VCN → subnet. Chicago-to-Chuncheon automatic list refresh is not guaranteed. Do not proceed with stale selections.
- Changing the region of a deployed stack is not a migration feature. Review a new Plan for replacements/deletions; never blindly Apply saved variables.
- Native Compute-style SSH key generation/private-key download in Resource Manager is not confirmed by official documentation. Generate keys locally if needed and supply only the public key. This project does not generate private keys into Terraform state.
- [Control research and Console checks](docs/research/resource-manager-controls.md)

## Data, archives and safety

Mattermost Team Edition and PostgreSQL run through Docker Compose. Data is bind-mounted under /srv/mattermost on the boot filesystem; no additional Block Volume is created. OS, images, DB, files, logs and archive temporary copies share space. The 50 GiB block volume does not imply a 50 GiB root filesystem: inspect df and filesystem layout.

For offline HTML archives and attachments, use the separate [Mattermost Archiver](https://github.com/AndyPandi/mattermost-archiver). It is not automatically installed by this stack and is not a complete backup/restore solution. DM/private-channel export requires separate authorization. Verify external copies and readability before deleting VM/boot storage.

Never commit private keys, real environment values, Terraform state or backups. Do not share env files, full docker inspect or resolved compose configuration containing secrets. Resource costs are the deployer's responsibility.

## Local checks

Terraform 1.7+ for mock tests (tested with 1.9.8), Python 3, PyYAML:

```sh
terraform init -backend=false
terraform fmt -check -recursive
terraform validate
terraform test
python3 tests/static_checks.py
python3 -m unittest discover -s tests -p "test_*.py"
```

These checks do not run OCI Apply; tests use mock providers. Independently authored project-contract checks are not official Oracle schema validation or proof of Console rendering. Read the state document for evidence and outstanding checks, including networking, reboot/persistence and restore tests. Docker's RHEL9 installation procedure is used on Oracle Linux; do not infer certification from compatibility.

## Documentation

- [Current state and validation checklist](docs/project-state.md)
- [Architecture](docs/architecture/system-overview.md)
- [Deployment decision](docs/decisions/ADR-002-deployment-and-archive.md)
- [Upstream Compose research](docs/research/upstream-compose.md)
- [Documentation rules](docs/README.md)

## Mattermost Team Edition license

This deployment pins the official **Team Edition 11.7.0** image by digest, not an Enterprise/Entry or trial image.

- **Commercial/internal operations:** the MIT license for the official Team compiled distribution permits commercial use and real operational use, not just evaluation/non-production. Infrastructure costs and operational responsibility remain yours.
- **Modification/redistribution:** MIT-covered software may be copied, modified, distributed and sold, provided copyright and permission notices remain in all copies or substantial portions. Review its no-warranty terms, bundled third-party licenses and Mattermost trademark policy as well.
- **Source is different:** do not apply the official binary's MIT license to the whole server source. The v11.7.0 source policy distinguishes AGPLv3/commercial licensing and directory-specific Apache-2.0 exceptions. Source modifications and custom builds require separate compliance review, including applicable AGPL source-offer obligations to users interacting with a modified server over a network.
- **Users and sizing:** the MIT text has no user-count cap. Product documentation targets Team at small teams under 250 activated users and does not recommend it for government or sensitive commercial workloads. That is not an MIT usage restriction or a performance guarantee for this VM; this review did not runtime-test a technical user ceiling in 11.7.0.
- **Enterprise/Entry/trials:** Entry is the free mode of the Enterprise distribution, not Team. The current Enterprise Free Version contract restricts use to evaluation, testing and non-production, with at most 100 end users. Small-team marketing or a running free instance does not establish production permission. Trials and subscriptions have their own terms.
- **Features:** do not generalize free/paid entitlement to every API or plugin. Check each feature's edition, version and subscription requirements for SSO, compliance, HA, AI and other capabilities, plus external-service costs. Current comparison pages are not runtime evidence for the pinned release.

Official sources: [licensing policy](https://docs.mattermost.com/product-overview/faq-license) · [edition comparison](https://docs.mattermost.com/product-overview/editions-and-offerings) · [paid-feature comparison](https://mattermost.com/pricing/) · [11.7.0 MIT text](https://github.com/mattermost/mattermost/blob/v11.7.0/server/build/MIT-COMPILED-LICENSE.md).
See [version-specific evidence and documentation/contract differences](docs/research/team-edition-license.md). This is a public-documentation summary, not legal advice or runtime validation.

## Repository license

This project's independently authored code, tests and documentation use the [MIT License](LICENSE), Copyright (c) 2026 AndyPandi. Third-party software, container contents and trademarks are not relicensed: see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

Read [SECURITY.md](SECURITY.md) before deployment or upgrades. Never share the administrator SSH private key with participants; provide individually revocable restricted access. New database initialization separates the bootstrap administrator and least-privileged application role; live PostgreSQL/Mattermost verification remains required. Digests do not pin dynamic OS/RPM selection or guarantee vulnerability-free software.

## IMDSv2-only metadata

Instances set `instance_options.are_legacy_imds_endpoints_disabled = true`; there is no opt-out. Updating GitHub does not update an existing stack or VM: upload the configuration, preserve existing inputs, **review the complete Plan, then Apply**. OCI provider 7.22.0 supports in-place updates of this option; other drift, including the latest OL9 image selection, can still cause replacement. See [impact review and read-only guest checks](SECURITY.md#imds-v2-only).
