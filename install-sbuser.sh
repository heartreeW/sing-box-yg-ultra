#!/usr/bin/env bash
set -Eeuo pipefail

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_FILE="$SOURCE_DIR/sb-multi-user.sh"
TARGET_FILE="${TARGET_FILE:-/usr/local/bin/sbuser}"

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "ERROR: Run as root, for example: sudo bash install-sbuser.sh" >&2
  exit 1
fi

if [[ ! -f "$SOURCE_FILE" ]]; then
  echo "ERROR: Missing $SOURCE_FILE" >&2
  exit 1
fi

install -m 0755 "$SOURCE_FILE" "$TARGET_FILE"

cat <<EOF
Installed: $TARGET_FILE

Now you can use:
  sbuser add alice bob
  sbuser list
  sbuser links alice
  sbuser remove alice
EOF
