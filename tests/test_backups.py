"""Isolated backup orchestration regressions: python3 -m unittest discover -s tests -p test_backups.py."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


STUB = r"""#!/usr/bin/env python3
import json
import os
from pathlib import Path
import sys

root = Path(os.environ["BACKUP_FIXTURE"])
state_path = root / "state.json"
state = json.loads(state_path.read_text()) if state_path.exists() else {}
command = Path(sys.argv[0]).name
args = sys.argv[1:]
with (root / "trace.jsonl").open("a") as out:
    out.write(json.dumps([command, args, os.environ.get("PGOPTIONS", "")]) + "\n")

def busy(key, count, reason):
    calls = state.get(key, 0)
    state[key] = calls + 1
    state_path.write_text(json.dumps(state))
    if calls < int(count):
        print(reason)

def backup_path(path):
    assert path.startswith("/root/"), path
    return root / "backups" / Path(path).name

if command == "db.sh":
    if args[0] == "psql":
        db = args[1]
        query = args[-1]
        if db == os.environ.get("CHECK_FAIL"):
            print("simulated status check failure", file=sys.stderr)
            sys.exit(7)
        if db == "postgres":
            if os.environ.get("AFFILIATIONS_EXISTS", "1") == "1":
                print("1")
        elif db == "devstats":
            if all(state.get("dump:" + db) for db in os.environ["TEST_DBS"].split()):
                busy("affs", os.environ.get("AFFS_BUSY", "0"), "affiliations import running")
        elif db == os.environ.get("BUSY_DB"):
            if os.environ.get("BUSY_AFTER_ARTIFICIAL") and not state.get("art:" + db):
                sys.exit(0)
            if os.environ.get("OLD_FLAG") and "interval '9 hours'" in query:
                sys.exit(0)
            busy(db, os.environ.get("BUSY_COUNT", "0"),
                 os.environ.get("BUSY_REASON", "sync running since 2000-01-01"))
    elif args[0] == "pg_dump":
        db = args[args.index("-f") - 1]
        target = backup_path(args[args.index("-f") + 1])
        target.write_text("partial" if db == os.environ.get("DUMP_FAIL") else "new:" + db)
        state["dump:" + db] = True
        state_path.write_text(json.dumps(state))
        if db == os.environ.get("DUMP_FAIL"):
            sys.exit(8)
    else:
        raise AssertionError(args)
elif command == "backup_artificial.sh":
    state["art:" + args[0]] = True
    state_path.write_text(json.dumps(state))
    if args[0] == os.environ.get("ARTIFICIAL_FAIL"):
        sys.exit(9)
elif command == "file_age.sh":
    print("0")
elif command == "mv":
    src, dest = map(backup_path, args[-2:])
    if dest.stem == os.environ.get("PUBLISH_FAIL"):
        print("simulated publish failure", file=sys.stderr)
        sys.exit(10)
    src.replace(dest)
elif command == "rm":
    for path in args:
        if not path.startswith("-"):
            backup_path(path).unlink(missing_ok=True)
elif command not in ("sleep", "wait_flag.sh", "set_flag.sh", "clear_flag.sh"):
    raise AssertionError(command)
"""


class BackupsTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="devstats-backups-test-")
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        for directory in ("devel", "devstats-helm", "bin", "backups"):
            (self.root / directory).mkdir()
        shutil.copyfile(
            Path(__file__).resolve().parents[1] / "devstats-helm" / "backups.sh",
            self.root / "devstats-helm" / "backups.sh",
        )
        for directory, names in (
            ("bin", ("db.sh", "sleep", "mv", "rm")),
            ("devel", ("file_age.sh", "wait_flag.sh", "set_flag.sh", "clear_flag.sh")),
            ("devstats-helm", ("backup_artificial.sh",)),
        ):
            for name in names:
                path = self.root / directory / name
                path.write_text(STUB)
                path.chmod(0o755)
        (self.root / "devel" / "all_dbs.sh").write_text('all="$TEST_DBS"\n')
        (self.root / "backups" / "recent.dump").write_text("previous")

    def run_backups(self, **overrides):
        env = os.environ.copy()
        for key in (
            "GIANT", "NOAGE", "SKIP_FLAGS", "BACKUP_WAIT_MAX", "BACKUP_WAIT_STEP",
            "CHECK_FAIL", "BUSY_DB", "BUSY_COUNT", "BUSY_REASON", "BUSY_AFTER_ARTIFICIAL", "OLD_FLAG",
            "DUMP_FAIL", "ARTIFICIAL_FAIL", "AFFS_BUSY", "AFFILIATIONS_EXISTS", "PUBLISH_FAIL",
        ):
            env.pop(key, None)
        env.update(
            BACKUP_FIXTURE=str(self.root),
            TEST_DBS="recent missing",
            PATH=str(self.root / "bin") + os.pathsep + env["PATH"],
            PGOPTIONS="-c application_name=backup-fixture",
        )
        env.update(overrides)
        result = subprocess.run(
            ["bash", "devstats-helm/backups.sh"], cwd=self.root, env=env,
            text=True, capture_output=True, timeout=30,
        )
        path = self.root / "trace.jsonl"
        self.trace = [json.loads(line) for line in path.read_text().splitlines()] if path.exists() else []
        self.output = result.stdout + result.stderr
        return result.returncode

    def full_backups(self):
        return [
            args[args.index("-f") - 1]
            for command, args, _ in self.trace
            if command == "db.sh" and args[0] == "pg_dump"
        ]

    def test_every_database_is_backed_up_sequentially_without_age_selection(self):
        self.assertEqual(self.run_backups(), 0, self.output)
        work = []
        for command, args, options in self.trace:
            if command == "backup_artificial.sh":
                work.append(("artificial", args[0]))
            elif command == "db.sh" and args[0] == "pg_dump":
                work.append(("full", args[args.index("-f") - 1]))
                self.assertIn("-Z1", args)
            if command in ("db.sh", "backup_artificial.sh"):
                self.assertIn("application_name=backup-fixture", options)
                self.assertIn("max_parallel_workers_per_gather=0", options)
                self.assertIn("work_mem=16MB", options)
        self.assertEqual(work, [
            ("artificial", "recent"), ("full", "recent"),
            ("artificial", "missing"), ("full", "missing"), ("full", "affiliations"),
        ])
        self.assertNotIn("file_age.sh", [entry[0] for entry in self.trace])
        for db in ("recent", "missing", "affiliations"):
            self.assertEqual((self.root / "backups" / (db + ".dump")).read_text(), "new:" + db)
        self.assertFalse(list((self.root / "backups").glob("*.dump.*")))

    def test_default_wait_survives_more_than_eight_hours(self):
        self.assertEqual(self.run_backups(
            BUSY_DB="recent", BUSY_COUNT="2", BACKUP_WAIT_STEP="30000",
        ), 0, self.output)
        self.assertEqual(self.full_backups(), ["recent", "missing", "affiliations"])
        self.assertEqual(sum(command == "sleep" for command, _, _ in self.trace), 2)

    def test_old_running_flag_is_still_busy(self):
        self.assertEqual(self.run_backups(
            BUSY_DB="recent", BUSY_COUNT="1", OLD_FLAG="1",
        ), 0, self.output)
        self.assertEqual(sum(command == "sleep" for command, _, _ in self.trace), 1)
        self.assertIn("2000-01-01", self.output)

    def test_unprovisioned_database_waits(self):
        self.assertEqual(self.run_backups(
            BUSY_DB="missing", BUSY_COUNT="1", BUSY_REASON="not provisioned",
        ), 0, self.output)
        self.assertIn("not provisioned", self.output)
        self.assertEqual(self.full_backups(), ["recent", "missing", "affiliations"])

    def test_sync_starting_after_artificial_archive_delays_full_dump(self):
        self.assertEqual(self.run_backups(
            BUSY_DB="recent", BUSY_COUNT="1", BUSY_AFTER_ARTIFICIAL="1",
        ), 0, self.output)
        work = [
            command for command, args, _ in self.trace
            if command in ("backup_artificial.sh", "sleep")
            or (command == "db.sh" and args[0] == "pg_dump")
        ]
        self.assertEqual(work[:3], ["backup_artificial.sh", "sleep", "db.sh"])

    def test_shared_affiliations_import_waits_before_shared_dump(self):
        self.assertEqual(self.run_backups(AFFS_BUSY="2"), 0, self.output)
        self.assertEqual(sum(command == "sleep" for command, _, _ in self.trace), 2)
        self.assertIn("affiliations import running", self.output)
        self.assertEqual(self.full_backups(), ["recent", "missing", "affiliations"])

    def test_explicit_wait_limit_reports_failure_but_continues(self):
        self.assertEqual(self.run_backups(
            BUSY_DB="recent", BUSY_COUNT="100", BACKUP_WAIT_MAX="60", BACKUP_WAIT_STEP="60",
        ), 1, self.output)
        self.assertEqual(self.full_backups(), ["missing", "affiliations"])
        self.assertEqual((self.root / "backups" / "recent.dump").read_text(), "previous")

    def test_failed_status_check_never_means_idle(self):
        self.assertEqual(self.run_backups(CHECK_FAIL="recent"), 1, self.output)
        self.assertEqual(self.full_backups(), ["missing", "affiliations"])
        self.assertIn("simulated status check failure", self.output)

    def test_failed_shared_lock_check_prevents_backups(self):
        self.assertEqual(self.run_backups(CHECK_FAIL="devstats"), 1, self.output)
        self.assertEqual(self.full_backups(), [])

    def test_failed_database_discovery_is_not_absence(self):
        self.assertEqual(self.run_backups(CHECK_FAIL="postgres"), 1, self.output)
        self.assertIn("simulated status check failure", self.output)

    def test_failed_full_dump_preserves_previous_and_continues(self):
        self.assertEqual(self.run_backups(DUMP_FAIL="recent"), 1, self.output)
        self.assertEqual(self.full_backups(), ["recent", "missing", "affiliations"])
        self.assertEqual((self.root / "backups" / "recent.dump").read_text(), "previous")
        self.assertFalse(list((self.root / "backups").glob("*.dump.*")))
        self.assertIn("Failed full backups: recent", self.output)

    def test_failed_publish_preserves_previous_dump(self):
        self.assertEqual(self.run_backups(PUBLISH_FAIL="recent"), 1, self.output)
        self.assertEqual((self.root / "backups" / "recent.dump").read_text(), "previous")
        self.assertFalse(list((self.root / "backups").glob("*.dump.*")))

    def test_failed_artificial_backup_is_reported_and_full_dump_still_runs(self):
        self.assertEqual(self.run_backups(ARTIFICIAL_FAIL="recent"), 1, self.output)
        self.assertEqual(self.full_backups(), ["recent", "missing", "affiliations"])
        self.assertIn("Failed artificial events backups: recent", self.output)

    def test_absent_shared_database_is_optional(self):
        self.assertEqual(self.run_backups(AFFILIATIONS_EXISTS="0"), 0, self.output)
        self.assertEqual(self.full_backups(), ["recent", "missing"])

    def test_explicit_flag_override_and_giant_cleanup_are_preserved(self):
        self.assertEqual(self.run_backups(
            SKIP_FLAGS="1", CHECK_FAIL="devstats", GIANT="lock",
        ), 0, self.output)
        self.assertEqual(self.full_backups(), ["recent", "missing", "affiliations"])
        self.assertEqual(self.trace[-1][0], "clear_flag.sh")

    def test_invalid_wait_configuration_fails_before_backup(self):
        for options in ({"BACKUP_WAIT_MAX": "-1"}, {"BACKUP_WAIT_STEP": "0"}, {"BACKUP_WAIT_STEP": "bad"}):
            with self.subTest(options=options):
                self.assertNotEqual(self.run_backups(**options), 0, self.output)
                self.assertEqual(self.full_backups(), [])


if __name__ == "__main__":
    unittest.main()
