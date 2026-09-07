import importlib.util
import json
import os
from pathlib import Path
import shlex
import subprocess
import tempfile
import unittest
from unittest.mock import patch


SCRIPT = Path(__file__).resolve().parents[1] / "contents/scripts/run-as-root.py"
spec = importlib.util.spec_from_file_location("run_as_root", SCRIPT)
launcher = importlib.util.module_from_spec(spec)
spec.loader.exec_module(launcher)


class RootLauncherTests(unittest.TestCase):
	def setUp(self):
		self.temp = tempfile.TemporaryDirectory()
		self.addCleanup(self.temp.cleanup)
		self.base = Path(self.temp.name)
		self.apps = self.base / "user/applications"
		self.apps.mkdir(parents=True)
		self.env = patch.dict(os.environ, {
			"XDG_DATA_HOME": str(self.apps.parent),
			"XDG_DATA_DIRS": str(self.base / "system"),
		})
		self.env.start()
		self.addCleanup(self.env.stop)

	def entry(self, name="test.desktop", extra="", command="/bin/echo %U"):
		path = self.apps / name
		path.parent.mkdir(parents=True, exist_ok=True)
		path.write_text("[Desktop Entry]\nType=Application\nName=Test App\nExec=" + command + "\n" + extra)
		return path

	def test_resolves_ids_urls_and_nested_entries(self):
		path = self.entry("sub/test app.desktop")
		for identifier in [str(path), path.as_uri(), "sub-test app.desktop",
				"applications:sub-test%20app.desktop", "applications://sub-test%20app.desktop"]:
			with self.subTest(identifier=identifier):
				self.assertEqual(launcher.desktop_file(identifier), path)

	def test_user_override_precedes_system_entry(self):
		path = self.entry()
		system = self.base / "system/applications"
		system.mkdir(parents=True)
		(system / path.name).write_text(path.read_text())
		self.assertEqual(launcher.desktop_file(path.name), path)

	def test_rejects_non_application_targets(self):
		for identifier in ["https://example.com/test.desktop", "file://remote/test.desktop",
				"../test.desktop", "https://example.com", "notes.txt"]:
			with self.subTest(identifier=identifier), self.assertRaises(ValueError):
				launcher.desktop_file(identifier)
		for extra in ["Type=Link\n", "Hidden=true\n"]:
			with self.assertRaises(ValueError):
				launcher.read_entry(self.entry(extra=extra))

	def test_field_codes_and_desktop_action_isolation(self):
		path = self.entry(extra="Icon=test icon\n[Desktop Action Wrong]\nExec=/bin/false\n",
			command='/bin/echo "two words" %U %i %c %k %% %f %d')
		self.assertEqual(launcher.exec_arguments(launcher.read_entry(path), path),
			["/bin/echo", "two words", "--icon", "test icon", "Test App", str(path), "%"])

	def test_escaping_and_empty_argument(self):
		path = self.entry(command=r'/bin/echo "" "a\\\\b" "\\$HOME" "\\`literal\\`"')
		self.assertEqual(launcher.exec_arguments(launcher.read_entry(path), path),
			["/bin/echo", "", "a\\b", "$HOME", "`literal`"])

	def test_invalid_commands_fail_before_elevation(self):
		for command in ["", '/bin/echo "unterminated', "/bin/echo %Z", "/bin/echo %", "/nonexistent/program"]:
			path = self.entry(command=command)
			with self.subTest(command=command), patch.object(launcher, "subprocess") as process:
				with self.assertRaises(ValueError):
					launcher.launch(str(path))
				process.call.assert_not_called()

	def test_kdesu_handoff_preserves_arguments_and_working_directory(self):
		workdir = self.base / "work ' directory"
		workdir.mkdir()
		path = self.entry(extra="Path=" + str(workdir) + "\n",
			command='/bin/echo %c %k "two words"')
		with patch.object(launcher, "kdesu_path", return_value="/mock/kdesu"), \
				patch.object(launcher.subprocess, "call", return_value=0) as call:
			self.assertEqual(launcher.launch(str(path)), 0)
		argv = call.call_args.args[0]
		self.assertEqual(argv[:4], ["/mock/kdesu", "-u", "root", "-c"])
		# Execute only the harmless captured echo command as the current user.
		result = subprocess.run(shlex.split(argv[4]), capture_output=True, text=True, check=True)
		self.assertEqual(result.stdout.strip(), "Test App " + str(path) + " two words")

	def test_metadata_cannot_inject_shell_commands(self):
		marker = self.base / "injected"
		name = "$(touch " + str(marker) + ") `touch " + str(marker) + "` ' ;"
		path = self.entry(extra="Name=" + name + "\n", command="/bin/echo %c")
		with patch.object(launcher, "kdesu_path", return_value="/mock/kdesu"), \
				patch.object(launcher.subprocess, "call", return_value=0) as call:
			launcher.launch(str(path))
		result = subprocess.run(shlex.split(call.call_args.args[0][4]), capture_output=True, text=True, check=True)
		self.assertEqual(result.stdout.strip(), name)
		self.assertFalse(marker.exists())

	def test_terminal_is_opt_in_regardless_of_desktop_entry(self):
		for terminal_flag in ["true", "false"]:
			path = self.entry(extra="Terminal=" + terminal_flag + "\n")
			with self.subTest(terminal_flag=terminal_flag), \
					patch.object(launcher, "kdesu_path", return_value="/mock/kdesu"), \
					patch.object(launcher.shutil, "which", side_effect=lambda value: "/usr/bin/" + Path(value).name) as which, \
					patch.object(launcher.subprocess, "call", return_value=0) as call:
				launcher.launch(str(path))
				self.assertEqual(call.call_args.args[0][:4], ["/mock/kdesu", "-u", "root", "-c"])
				self.assertNotIn("-t", call.call_args.args[0])
				self.assertNotIn(unittest.mock.call("konsole"), which.call_args_list)
				launcher.launch(str(path), show_terminal=True)
				self.assertEqual(call.call_args.args[0][:7],
					["/usr/bin/konsole", "--separate", "-e", "/mock/kdesu", "-u", "root", "-c"])
				self.assertEqual(call.call_args.args[0][-1], "-t")

	def test_cli_uses_kdesu_from_path(self):
		binary = self.base / "bin"
		binary.mkdir()
		capture = self.base / "argv.json"
		fake = binary / "kdesu"
		fake.write_text("#!/usr/bin/python3\nimport json, sys\nfrom pathlib import Path\n"
			+ "Path(" + repr(str(capture)) + ").write_text(json.dumps(sys.argv[1:]))\n")
		fake.chmod(0o700)
		path = self.entry()
		env = dict(os.environ, PATH=str(binary) + os.pathsep + os.environ["PATH"])
		subprocess.run(["python3", str(SCRIPT), path.as_uri()], env=env, check=True)
		self.assertEqual(json.loads(capture.read_text())[:3], ["-u", "root", "-c"])


if __name__ == "__main__":
	unittest.main()
