# Server Health Check

A simple Bash script that connects to a list of servers over SSH and reports disk usage, memory usage, and failed SSH login attempts.

## Features

- Reads servers from a text file (one per line, `#` comments and empty lines are ignored)
- Checks disk usage of `/`
- Checks memory usage
- Counts failed SSH login attempts from `/var/log/auth.log`
- Keeps going if a server is unreachable and reports the error
- Strict mode (`set -euo pipefail`) and cleanup with `trap`

## Requirements

- Bash
- SSH access to the servers (SSH keys recommended, so no password prompts)
- A user that can read `/var/log/auth.log` on the servers (may need `sudo` or group access)

## Usage

```bash
chmod +x final_project_bash.sh
./final_project_bash.sh -f <servers_file> -u <remote_user>
```

| Option | Description |
|--------|-------------|
| `-f`   | File with one server per line |
| `-u`   | SSH username |
| `-h`   | Show help |

## Example

`servers.txt`:

```
# my servers
server1.example.com
192.168.1.20
```

Run:

```bash
./final_project_bash.sh -f servers.txt -u guirgis
```

Sample output:

```
[INFO] Checking health of server: server1.example.com
Checking disk space...
Disk Usage: 45% (20G / 50G)
memory usage...
Memory Usage: 1200MB / 4000MB (30.00%)
security check...
Failed SSH login attempts: 3
```

## Notes

- Make sure `servers.txt` uses Linux line endings (LF). Files edited on Windows may contain `\r` characters that break hostnames. Fix with: `sed -i 's/\r$//' servers.txt`
- The temporary log file is deleted when the script exits.

## What I Learned

`getopts`, functions, heredocs with SSH, error handling in Bash, and `awk` basics.
