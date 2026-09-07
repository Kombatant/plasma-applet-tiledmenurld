#!/usr/bin/env python3
"""Launch a desktop entry's Exec command through KDE's password dialog."""

import argparse
import configparser
import os
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import sys
from urllib.parse import unquote, urlsplit


def desktop_file(launcher):
	if launcher.startswith("applications:"):
		launcher = unquote(launcher[len("applications:"):].lstrip("/"))
	elif launcher.startswith("file:"):
		url = urlsplit(launcher)
		if url.netloc not in ("", "localhost") or url.query or url.fragment:
			raise ValueError("Only local application launchers are supported.")
		launcher = unquote(url.path)
	path = Path(launcher)
	if path.suffix != ".desktop":
		raise ValueError("Not an application desktop entry.")
	if path.is_absolute():
		if path.is_file():
			return path
	elif "/" not in launcher and "\\" not in launcher and ":" not in launcher:
		data_home = os.environ.get("XDG_DATA_HOME") or str(Path.home() / ".local/share")
		data_dirs = os.environ.get("XDG_DATA_DIRS") or "/usr/local/share:/usr/share"
		for directory in [data_home, *data_dirs.split(":")]:
			if not os.path.isabs(directory):
				continue
			apps = Path(directory) / "applications"
			if (apps / launcher).is_file():
				return apps / launcher
			# Desktop IDs flatten subdirectories with '-', e.g. kde-foo.desktop.
			for candidate in sorted(apps.rglob("*.desktop")):
				if str(candidate.relative_to(apps)).replace("/", "-") == launcher:
					return candidate
	else:
		raise ValueError("Only local application launchers are supported.")
	raise ValueError("Application desktop entry was not found: " + launcher)


def unescape(value):
	escapes = {"s": " ", "n": "\n", "t": "\t", "r": "\r", "\\": "\\"}
	return re.sub(r"\\([sntr\\])", lambda match: escapes[match[1]], value)


def read_entry(path):
	config = configparser.ConfigParser(interpolation=None, strict=False, delimiters=("=",))
	config.optionxform = str
	with path.open(encoding="utf-8") as stream:
		config.read_file(stream)
	entry = config["Desktop Entry"]
	if entry.get("Type") != "Application" or entry.get("Hidden", "false").lower() == "true":
		raise ValueError("This desktop entry is not an available application.")
	return {key: unescape(value) for key, value in entry.items()}


def split_exec(command):
	# Desktop Exec quoting resembles shell quoting, but also unescapes \$ and
	# \` inside double quotes (which Python's shlex deliberately preserves).
	args, current = [], []
	quote, started = "", False
	index = 0
	while index < len(command):
		char = command[index]
		if char == "\\" and quote != "'":
			index += 1
			if index == len(command):
				raise ValueError("Trailing escape in desktop Exec command.")
			current.append(command[index])
			started = True
		elif quote:
			if char == quote:
				quote = ""
			else:
				current.append(char)
		elif char in "\"'":
			quote, started = char, True
		elif char.isspace():
			if started:
				args.append("".join(current))
			current, started = [], False
		else:
			current.append(char)
			started = True
		index += 1
	if quote:
		raise ValueError("Unclosed quote in desktop Exec command.")
	if started:
		args.append("".join(current))
	return args


def exec_arguments(entry, path):
	# Expand field codes once, after quoting. Never evaluate Exec as shell source.
	args = []
	def expand(match):
		code = match[1]
		if not code:
			raise ValueError("Trailing field-code marker in desktop Exec command.")
		if code in "fFuUdDnNvm":
			return ""
		if code == "%":
			return "%"
		if code == "c":
			return entry.get("Name", "")
		if code == "k":
			return str(path)
		raise ValueError("Unsupported desktop Exec field code: %" + code)
	for arg in split_exec(entry.get("Exec", "")):
		if arg == "%i":
			if entry.get("Icon"):
				args.extend(["--icon", entry["Icon"]])
			continue
		value = re.sub(r"%(.)?", expand, arg)
		if value or arg == "":
			args.append(value)
	if not args or not args[0]:
		raise ValueError("This application has no executable command.")
	# Resolve using the user's PATH before kdesu changes the environment.
	executable = shutil.which(args[0])
	if not executable:
		raise ValueError("Application executable was not found: " + args[0])
	args[0] = executable
	return args


def kdesu_path():
	# Many distributions install kdesu in the KF6 libexec directory, off PATH.
	for candidate in [shutil.which("kdesu"), "/usr/lib/kf6/kdesu",
			"/usr/libexec/kf6/kdesu", "/usr/lib64/kf6/kdesu"]:
		if candidate and os.path.isfile(candidate) and os.access(candidate, os.X_OK):
			return candidate
	raise ValueError("kdesu was not found. Install your distribution's kdesu package.")


def launch(launcher, show_terminal=False):
	path = desktop_file(launcher)
	entry = read_entry(path)
	args = exec_arguments(entry, path)
	command = "exec " + shlex.join(args)
	if entry.get("Path"):
		command = "cd -- " + shlex.quote(entry["Path"]) + " && " + command
	# Use an explicit POSIX shell; root's login shell need not be POSIX.
	argv = [kdesu_path(), "-u", "root", "-c", shlex.join(["/bin/sh", "-c", command])]
	if entry.get("Icon"):
		argv.extend(["-i", entry["Icon"]])
	# The user's preference overrides the desktop entry's Terminal flag.
	if show_terminal:
		terminal = shutil.which("konsole")
		if not terminal:
			raise ValueError("Konsole is required when running as root in a terminal.")
		argv = [terminal, "--separate", "-e", *argv, "-t"]
	return subprocess.call(argv)


if __name__ == "__main__":
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("--terminal", action="store_true", help="Show the application in Konsole")
	parser.add_argument("launcher")
	options = parser.parse_args()
	try:
		sys.exit(launch(options.launcher, options.terminal))
	except (OSError, ValueError, KeyError, configparser.Error) as error:
		print(str(error), file=sys.stderr)
		sys.exit(1)
