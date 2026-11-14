"""Local secret-generation and SQL transport tests; not a live PostgreSQL test."""
import os
import pathlib
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
SCRIPT = (ROOT / 'cloud-init/bootstrap.sh').read_text().split("python3 - <<'PY'\n", 1)[1].split('\nPY', 1)[0]

class DatabaseInit(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.base = pathlib.Path(self.tmp.name)
        self.secrets = self.base / 'secrets'
        self.data = self.base / 'data'
        self.secrets.mkdir()
        self.data.mkdir()
        self.code = SCRIPT.replace('/opt/mattermost', str(self.secrets)).replace('/srv/mattermost/postgres', str(self.data))

    def run_init(self):
        exec(compile(self.code, '<secret-init>', 'exec'), {})

    def test_new_and_rerun(self):
        self.run_init()
        before = {p.name: p.read_text() for p in self.secrets.iterdir()}
        self.assertNotEqual(before['db-password'], before['db-admin-password'])
        self.assertNotIn(before['db-admin-password'], before['mattermost.env'])
        self.assertIn('POSTGRES_USER=mmadmin\n', before['postgres.env'])
        (self.data / 'PG_VERSION').write_text('17')
        self.run_init()
        self.assertEqual(before, {p.name: p.read_text() for p in self.secrets.iterdir()})
        for p in self.secrets.iterdir():
            self.assertEqual(p.stat().st_mode & 0o777, 0o600)

    def test_legacy_fails_without_changes(self):
        (self.data / 'PG_VERSION').write_text('17')
        (self.secrets / 'db-password').write_text('a' * 64)
        with self.assertRaises(SystemExit):
            self.run_init()
        self.assertEqual([p.name for p in self.secrets.iterdir()], ['db-password'])

    def test_invalid_secret_fails_without_admin_creation(self):
        (self.secrets / 'db-password').write_text('invalid')
        with self.assertRaises(SystemExit):
            self.run_init()
        self.assertFalse((self.secrets / 'db-admin-password').exists())

    def test_missing_existing_secret_fails(self):
        self.run_init()
        (self.data / 'PG_VERSION').write_text('17')
        (self.secrets / 'db-password').unlink()
        with self.assertRaises(SystemExit):
            self.run_init()
        self.assertFalse((self.secrets / 'db-password').exists())

    def test_sql_via_stdin_and_restricted_role(self):
        # Stub captures locally generated test values only. No daemon required.
        stub = self.base / 'psql'
        stub.write_text('#!/bin/sh\nprintf "%s\n" "$@" > "$CAPTURE.args"\ncat > "$CAPTURE.sql"\n')
        stub.chmod(0o700)
        env = dict(os.environ, PATH=str(self.base) + ':' + os.environ['PATH'],
                   MM_APP_PASSWORD='a' * 64, POSTGRES_USER='mmadmin', CAPTURE=str(self.base / 'capture'))
        result = subprocess.run(['sh', str(ROOT / 'cloud-init/init-db.sh')], env=env, capture_output=True)
        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stdout + result.stderr, b'')
        self.assertNotIn('a' * 64, (self.base / 'capture.args').read_text())
        sql = (self.base / 'capture.sql').read_text()
        self.assertIn('NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS', sql)
        self.assertIn('CREATE DATABASE mattermost OWNER mmuser', sql)
        env['MM_APP_PASSWORD'] = "bad'input"
        self.assertNotEqual(subprocess.run(['sh', str(ROOT / 'cloud-init/init-db.sh')], env=env, capture_output=True).returncode, 0)

if __name__ == '__main__':
    unittest.main()
