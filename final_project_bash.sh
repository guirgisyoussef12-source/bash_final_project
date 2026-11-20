#!/usr/bin/env bash
#strict mode
set -euo pipefail
LOG_FILE=$(mktemp /tmp/server_health.XXXXXX)
readonly LOG_FILE
log_info() {
  echo "[INFO] $1" | tee -a "$LOG_FILE"
}
log_error() {
  echo "[ERROR] $1" | tee -a "$LOG_FILE" >&2
}
print_usage() {
  echo "Usage: $0 -f <servers_file> -u <remote_user>"
  echo "Options:"
  echo "  -f <file>   File with one server per line (lines starting with # are ignored)"
  echo "  -u <user>   SSH username used to connect to the servers"
  echo "  -h          Show this help message"
  echo "Example: $0 -f servers.txt -u guirgis"
}

cleanup() {
echo "Cleaning up..."
  rm -f "$LOG_FILE"
}
trap cleanup EXIT
echo "Starting server health check..."
check_server_health() {
local server="$1"
local user="$2"
log_info "Checking health of server: $server"
if ! ssh -o connecttimeout=5 "${user}@${server}" <<'EOF'
echo "Checking disk space..."
df -h / | awk 'NR==2 {print "Disk Usage: " $5 " (" $3 " / " $2 ")"}'
echo "memory usage..."
free -m | awk 'NR==2 {printf "Memory Usage: %sMB / %sMB (%.2f%%)\n", $3, $2, ($3*100/$2)}'
echo "security check..."
auth_log="/var/log/auth.log"
if [[ -f "$auth_log" ]]; then
  count=$(grep -c "Failed password" "$auth_log")
  echo "Failed SSH login attempts: $count"
else
  echo "Auth log file not found."
fi
EOF
then
log_error "Failed to connect to server: $server"
fi
}
main(){
local server_file=""
local remote_user=""
while getopts ":f:u:h" opt; do
case $opt in
f)
server_file="$OPTARG"
;;
u)
remote_user="$OPTARG"
;;
h)
print_usage
exit 0
;;
\?)
log_error "Invalid option: -$OPTARG"
print_usage
exit 1
;;
:)
log_error "Option -$OPTARG requires an argument."
print_usage
exit 1
;;
esac
done
if [[ -z "$server_file" || -z "$remote_user" ]]; then
log_error "Error: Both server file and remote user must be provided."
print_usage
exit 1
fi
if [[ ! -f "$server_file" ]]; then
log_error "Error: Server file '$server_file' does not exist."
exit 1
fi
log_info "starting health checks for servers listed in $server_file as user $remote_user"
declare -a servers=()
while IFS= read -r line; do
if [[ -z "$line" || "$line" == \#* ]]; then
continue
fi
servers+=("$line")
done < "$server_file"
if [[ ${#servers[@]} -eq 0 ]]; then
log_error "Error: No valid servers found in the file."
exit 1
fi
log_info "Found ${#servers[@]} servers to check."
log_info "Starting health checks..."
for server_host in "${servers[@]}"; do
 check_server_health "$server_host" "$remote_user"
done
}
main "$@"