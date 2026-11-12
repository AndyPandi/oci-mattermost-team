"""Offline structural checks. Requires PyYAML; never executes guest bootstrap."""
import ast
import pathlib
import re
import subprocess
import yaml

root = pathlib.Path(__file__).resolve().parents[1]
schema = yaml.safe_load((root / 'schema.yaml').read_text())
variables = set(re.findall(r'variable "([^"]+)"', (root / 'variables.tf').read_text()))
assert variables == set(schema['variables'])
assert variables == {v for g in schema['variableGroups'] for v in g['variables']}
for ref in re.findall(r'${(w+)}', (root / 'schema.yaml').read_text()):
    assert ref in variables, ref
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
