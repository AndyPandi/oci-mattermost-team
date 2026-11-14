"""Offline structural checks. Requires PyYAML and jsonschema; never executes guest bootstrap."""
import ast
import copy
import json
from jsonschema import Draft7Validator
import pathlib
import re
import subprocess
import yaml

root = pathlib.Path(__file__).resolve().parents[1]
schema = yaml.safe_load((root / 'schema.yaml').read_text())
variables = set(re.findall(r'variable "([^"]+)"', (root / 'variables.tf').read_text()))
assert variables == set(schema['variables'])
assert variables == {v for g in schema['variableGroups'] for v in g['variables']}
for ref in re.findall(r'\$\{([\w.]+)\}', (root / 'schema.yaml').read_text()):
    assert ref in variables or ref == 'session.region', ref
assert 'readOnly:' not in (root / 'schema.yaml').read_text()
compose = yaml.safe_load((root / 'compose.yaml').read_text())
mm = compose['services']['mattermost']
pg = compose['services']['postgres']
assert mm['ports'] == ['127.0.0.1:8065:8065']
assert 'ports' not in pg
assert 'mattermost-team-edition:11.7.0@sha256:' in mm['image']
assert pg['volumes'] == ['/srv/mattermost/postgres:/var/lib/postgresql/data:Z']
for service in compose['services'].values():
    assert service['restart'] == 'unless-stopped'
    assert 'healthcheck' in service and 'logging' in service
    assert '@sha256:' in service['image']
    assert all(v.startswith('/srv/mattermost/') and v.endswith(':Z') for v in service['volumes'])
script = (root / 'cloud-init/bootstrap.sh').read_text()
subprocess.run(['bash', '-n', str(root / 'cloud-init/bootstrap.sh')], check=True)
embedded = script.split("python3 - <<'PY'\n", 1)[1].split('\nPY', 1)[0]
ast.parse(embedded)
assert 'set -x' not in script and 'setenforce' not in script
assert '0o600' in embedded and 'secrets.token_hex(32)' in embedded
main = (root / 'main.tf').read_text()
assert re.search(r'boot_volume_size_in_gbs\s*=\s*50', main)
assert not re.search(r'resource "oci_core_(volume|volume_attachment|boot_volume)"', main)
print('PASS: variable/schema consistency, conditional references, Compose safety, shell and embedded Python syntax, fixed boot-only storage')

# Official control definitions are checked directly: Oracle's published full meta
# schema defines sshPublicKeyVariable but omits it from dynamicVariable.oneOf.
meta = json.loads((root / 'tests/fixtures/orm-controls-meta.json').read_text())
controls = {'region': 'regionVariable', 'availability_domain': 'availabilityDomainVariable',
            'existing_vcn_id': 'vcnVariable', 'existing_subnet_id': 'subnetVariable',
            'ssh_public_key': 'sshPublicKeyVariable'}
for name, definition in controls.items():
    validator = Draft7Validator(dict(meta, **{'$ref': '#/definitions/' + definition}))
    validator.validate(schema['variables'][name])
    if name in ('availability_domain', 'existing_vcn_id', 'existing_subnet_id'):
        # Do not silently invent an unsupported region dependency. See research.
        for key in ('region', 'regionName'):
            candidate = copy.deepcopy(schema['variables'][name])
            candidate['dependsOn'][key] = '${region}'
            assert not validator.is_valid(candidate), (name, key)
assert schema['variables']['region']['default'] == '${session.region}'
assert schema['variables']['ssh_public_key']['additionalProps'] == {'allowMultiple': False}
assert schema['variables']['ssh_public_key']['required'] is True
assert 'default' not in schema['variables']['ssh_public_key']  # no array default
assert schema['variables']['availability_domain']['dependsOn'] == {'compartmentId': '${compartment_ocid}'}
assert schema['variables']['existing_vcn_id']['dependsOn'] == {'compartmentId': '${compartment_ocid}'}
assert schema['variables']['existing_subnet_id']['dependsOn'] == {'compartmentId': '${compartment_ocid}', 'vcnId': '${existing_vcn_id}'}
assert re.search(r'variable "ssh_public_key"\s*{\s*type\s*=\s*string', (root / 'variables.tf').read_text())
assert 'ssh_authorized_keys = trimspace(var.ssh_public_key)' in main
assert 'region = var.region' in (root / 'versions.tf').read_text()
assert 'tls_private_key' not in main
print('PASS: official control definitions, supported dependency keys, single public-key string, provider region')

# Generic deployment wording must not change existing network DNS identities.
assert schema['title'] == 'OCI deployment — Mattermost Team Edition'
assert schema['variables']['instance_name']['default'] == 'mattermost'
assert re.search(r'variable "instance_name"\s*{\s*type\s*=\s*string\s*default\s*=\s*"mattermost"', (root / 'variables.tf').read_text())
assert re.search(r'dns_label\s*=\s*"pocvcn"', main)
assert re.search(r'dns_label\s*=\s*"pocsubnet"', main)
for filename in ('README.md', 'README.en.md'):
    manual = (root / filename).read_text()
    assert not re.search(r'\bpoc\b|proof.of.concept', manual, re.I)
    assert manual.count('[![Deploy to Oracle Cloud]') == 1
    assert 'docs/research/team-edition-license.md' in manual
    assert 'https://docs.mattermost.com/product-overview/faq-license' in manual
print('PASS: generic manuals, one deploy button, name defaults, preserved network DNS labels')

# SSH IPv4 validation and required input (no world-open default).
ssh_cidr = schema['variables']['ssh_ingress_cidr']
assert ssh_cidr['required'] is True and 'default' not in ssh_cidr
cidr_variable = (root / 'variables.tf').read_text().split('variable "ssh_ingress_cidr" {', 1)[1].split('variable "network_mode"', 1)[0]
assert 'default' not in cidr_variable
for prefix in range(33):
    assert re.fullmatch(ssh_cidr['pattern'], f'203.0.113.1/{prefix}')
for cidr in ('0.0.0.0/0', '255.255.255.255/32'):
    assert re.fullmatch(ssh_cidr['pattern'], cidr)
for cidr in ('::/0', '2001:db8::1/128', '256.1.1.1/24', '203.0.113.1/33',
             '203.0.113.1/-1', '203.0.113.1', 'not-a-cidr', '1.2.3/24', '1.2.3.4/1.5'):
    assert not re.fullmatch(ssh_cidr['pattern'], cidr), cidr
print('PASS: SSH IPv4 /0–/32 schema validation, malformed/IPv6 rejection, no world-open default')
