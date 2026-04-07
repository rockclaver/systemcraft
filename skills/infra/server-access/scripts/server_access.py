#!/usr/bin/env python3
import argparse
import json
import os
import subprocess
import sys
from pathlib import Path


def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)


def expand(value):
    return os.path.expandvars(os.path.expanduser(value)) if isinstance(value, str) else value


def load_config(path_str):
    path = Path(expand(path_str))
    if not path.exists():
        raise FileNotFoundError(f"Config file not found: {path}")

    text = path.read_text(encoding="utf-8")
    suffix = path.suffix.lower()

    if suffix == ".json":
        data = json.loads(text)
    elif suffix in {".yml", ".yaml"}:
        try:
            import yaml  # type: ignore
        except Exception as exc:
            raise RuntimeError("PyYAML is required to read YAML config files") from exc
        data = yaml.safe_load(text)
    else:
        raise ValueError(f"Unsupported config extension: {suffix}")

    if not isinstance(data, dict):
        raise ValueError("Config root must be an object/map")
    servers = data.get("servers")
    if not isinstance(servers, list):
        raise ValueError("Config must contain a 'servers' list")
    return data


def resolve_server(data, name):
    wanted = name.strip().lower()
    matches = []
    for entry in data.get("servers", []):
        if not isinstance(entry, dict):
            continue
        entry_name = str(entry.get("name", "")).strip()
        if entry_name.lower() == wanted:
            matches.append(entry)
    if not matches:
        raise KeyError(f"Server not found: {name}")
    if len(matches) > 1:
        raise ValueError(f"Duplicate server name in config: {name}")
    server = matches[0]
    if not server.get("host"):
        raise ValueError(f"Server '{name}' is missing required field: host")
    return server


def build_ssh_command(server, remote_command, timeout_seconds=20):
    ssh_cmd = [
        "ssh",
        "-o",
        "BatchMode=yes",
        "-o",
        "ConnectTimeout=10",
        "-o",
        "StrictHostKeyChecking=accept-new",
    ]

    key = server.get("key")
    if key:
        ssh_cmd.extend(["-i", expand(str(key)), "-o", "IdentitiesOnly=yes"])

    user = server.get("user")
    host = str(server["host"])
    target = f"{user}@{host}" if user else host
    ssh_cmd.append(target)
    wrapped_command = f"timeout {int(timeout_seconds)} bash -lc {json.dumps(remote_command)}"
    ssh_cmd.append(wrapped_command)
    return ssh_cmd


def run_remote(server, remote_command, timeout_seconds=20):
    cmd = build_ssh_command(server, remote_command, timeout_seconds=timeout_seconds)
    proc = subprocess.run(cmd, capture_output=True, text=True)
    return proc


def command_inspect(args):
    data = load_config(args.config)
    server = resolve_server(data, args.server)
    remote_parts = list(args.remote_command)
    if remote_parts and remote_parts[0] == "--":
        remote_parts = remote_parts[1:]
    remote_command = " ".join(remote_parts)
    if not remote_command:
        raise ValueError("Missing remote command after --")
    proc = run_remote(server, remote_command, timeout_seconds=args.timeout)
    print(json.dumps({
        "server": {
            "name": server.get("name"),
            "host": server.get("host"),
            "user": server.get("user"),
            "key": server.get("key"),
        },
        "exitCode": proc.returncode,
        "stdout": proc.stdout,
        "stderr": proc.stderr,
        "command": remote_command,
    }, indent=2))
    return 0 if proc.returncode == 0 else proc.returncode


def command_docker_stopped(args):
    data = load_config(args.config)
    server = resolve_server(data, args.server)
    remote_command = "docker ps -a --filter status=exited --format '{{json .}}'"
    proc = run_remote(server, remote_command, timeout_seconds=args.timeout)

    result = {
        "server": {
            "name": server.get("name"),
            "host": server.get("host"),
            "user": server.get("user"),
        },
        "exitCode": proc.returncode,
        "stderr": proc.stderr,
        "containers": [],
    }

    if proc.returncode == 0:
        lines = [line.strip() for line in proc.stdout.splitlines() if line.strip()]
        for line in lines:
            try:
                result["containers"].append(json.loads(line))
            except json.JSONDecodeError:
                result["containers"].append({"raw": line})

    print(json.dumps(result, indent=2))
    return 0 if proc.returncode == 0 else proc.returncode


def main():
    parser = argparse.ArgumentParser(description="Resolve SSH server entries and run remote checks")
    parser.add_argument("--config", required=True, help="Path to creds.yml or creds.json")

    sub = parser.add_subparsers(dest="command", required=True)

    inspect = sub.add_parser("inspect", help="Run an arbitrary remote command")
    inspect.add_argument("--server", required=True, help="Server name from config")
    inspect.add_argument("--timeout", type=int, default=20, help="Remote timeout seconds")
    inspect.add_argument("remote_command", nargs=argparse.REMAINDER)
    inspect.set_defaults(func=command_inspect)

    docker_stopped = sub.add_parser("docker-stopped", help="List stopped Docker containers on a server")
    docker_stopped.add_argument("--server", required=True, help="Server name from config")
    docker_stopped.add_argument("--timeout", type=int, default=20, help="Remote timeout seconds")
    docker_stopped.set_defaults(func=command_docker_stopped)

    args = parser.parse_args()
    try:
        return args.func(args)
    except Exception as exc:
        eprint(f"ERROR: {exc}")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
