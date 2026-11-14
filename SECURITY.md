# Security and operating responsibilities

This deployment is not a hardened managed service, a compliance certification, or a CVE-free guarantee. Report suspected issues privately to the repository owner through an existing private contact; do not put keys, credentials, state, logs or vulnerability exploits in public issues. No guaranteed response SLA is offered.

## Boundaries

- Mattermost binds only to host 127.0.0.1:8065; PostgreSQL publishes no host port. Use an explicitly loopback-bound SSH tunnel. Never share the administrator's opc private key with participants. Arrange individually revocable, restricted access (or a separately reviewed HTTPS deployment) before onboarding users; this stack does not provision restricted participant accounts.
- SSH CIDR is required with no default. Prefer your public /32. Explicit /0 remains permitted by user choice and exposes SSH to all IPv4. Existing subnet rules can widen exposure. Key authentication is not protection against every SSH vulnerability.
- Protect first administrator registration; restrict tunnels/access until completed. HTTPS, external identity integration and application-level authorization require separate review.
- Host root and Docker access are root-equivalent and can read container environments, DB secrets and data. Secrets are guest-generated, root-only 0600 files under /opt/mattermost, never Terraform inputs/state or password command arguments. Do not publish docker inspect, resolved compose output or env files. DB traffic is internal Docker-network plaintext, not TLS.
- New databases use mmadmin as bootstrap superuser with a separate random secret. Mattermost gets only mmuser: NOSUPERUSER, NOCREATEDB, NOCREATEROLE, NOREPLICATION, NOBYPASSRLS; it owns its database to perform schema migrations. This is not isolation against an attacker controlling the host or all application data.
- The read-only init script runs only on empty PGDATA. Bootstrap reruns retain secrets. Missing/invalid secrets or a legacy DB without split credentials fail closed; they do not rotate passwords, demote roles or delete data. A failed partial PostgreSQL initialization requires private diagnosis; never delete PGDATA to make a retry pass.

## Existing installations: explicit maintenance, not automatic migration

Old installations created mmuser as a PostgreSQL superuser. Updating Git/stack code does not remediate that live database. Do not rerun the new bootstrap or replace live Compose blindly; retain the previous working configuration while scheduling migration. Never fabricate db-admin-password merely to bypass the guard.

1. Restrict access, schedule downtime and stop Mattermost writes. Take an encrypted external PostgreSQL logical backup (including role/ownership information) and matching files/config backup; prove restoration in an isolated environment first. Keep the old configuration and secrets for recovery. Do not copy a live PGDATA directory as a consistent backup.
2. Preferred path: provision a separately reviewed fresh split-role database, restore application schema/data with ownership mapped to mmuser and without restoring legacy superuser attributes, then test migrations/login/uploads before cutover. Keep the original intact until rollback and restore are proven.
3. Expert in-place alternative: with the existing mmuser administration session, create a separate mmadmin LOGIN SUPERUSER and a new random hex secret. Use a protected local interactive psql session and its password prompt (not SQL/password arguments, shell history or logged statements); store the matching value in root-only db-admin-password. Verify a separate authenticated admin connection before changing mmuser. Never close your only working admin path prematurely.
4. Inventory database/schema/object ownership, extensions and role memberships. As mmadmin, ensure mmuser owns mattermost and required objects, remove unexpected privileged memberships, then explicitly run: ALTER ROLE mmuser NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS; Do not demote other roles or mass-reassign unrelated databases. Preserve the application password and db-password file.
5. Review the new env/Compose/init files, regenerate env with the reviewed bootstrap only after both canonical secrets match live roles. PostgreSQL initialization variables do not change existing DB passwords. Verify role flags and membership, authentication, Mattermost schema migration, API, attachments and reboot. If any step fails, stop and recover using the tested backup/old configuration; do not silently rotate secrets or reset volumes.

This is a maintenance checklist requiring a PostgreSQL-capable operator, not a tested one-command migration. Verify mmuser flags with pg_roles, database ownership and application behavior on the actual target. Local unit tests do not establish PostgreSQL runtime compatibility.

## Patching and recovery

Operators must monitor upstream advisories for Mattermost, PostgreSQL, Docker/containerd, OCI provider, OS and dependencies; stage updates, review licenses, back up and test rollback/migrations. Image digests pin bytes, not absence of vulnerabilities or ongoing security updates. Oracle Linux image selection and Docker RPM versions remain dynamic; provider lock/digests do not make the entire VM reproducible. Review every Plan and package change.

Keep external encrypted backups of DB, uploads/config and required secrets with least-privilege access and retention; test restoration regularly. HTML archives are not full disaster-recovery backups. The 50 GiB boot filesystem is shared by OS, images, DB, uploads and logs; monitor capacity continuously. Destroy/boot deletion can remove all local data. Container capability stripping/no-new-privileges has not been added without testing PostgreSQL entrypoint/ownership behavior. See [current validation limits](docs/project-state.md).
