#!/usr/bin/env bash
set -Eeuo pipefail

SBOX_DIR="${SBOX_DIR:-/etc/s-box}"
REGISTRY="${REGISTRY:-$SBOX_DIR/multi-users.tsv}"
USER_DIR="${USER_DIR:-$SBOX_DIR/users}"
CONFIG_CANDIDATES=("$SBOX_DIR/sb.json" "$SBOX_DIR/sb10.json" "$SBOX_DIR/sb11.json")

usage() {
  cat <<'EOF'
sing-box-yg multi-user helper

Run this script on the VPS after sing-box-yg has installed /etc/s-box/sb.json.

Usage:
  sudo bash sb-multi-user.sh add alice [bob ...]
  sudo bash sb-multi-user.sh remove alice|uuid [bob|uuid ...]
  sudo bash sb-multi-user.sh list
  sudo bash sb-multi-user.sh links alice|uuid
  sudo bash sb-multi-user.sh check

Files touched:
  /etc/s-box/sb.json
  /etc/s-box/sb10.json, /etc/s-box/sb11.json if they exist
  /etc/s-box/multi-users.tsv
  /etc/s-box/users/<name>.txt
EOF
}

info() {
  printf 'INFO: %s\n' "$*"
}

warn() {
  printf 'WARN: %s\n' "$*" >&2
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

need_root() {
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    return 0
  fi
  if [[ "$SBOX_DIR" != "/etc/s-box" && -w "$SBOX_DIR" ]]; then
    return 0
  fi
  die "Run as root, for example: sudo bash $0 $*"
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing command: $1"
}

config_files() {
  local f found
  found=1
  for f in "${CONFIG_CANDIDATES[@]}"; do
    if [[ -f "$f" ]]; then
      printf '%s\n' "$f"
      found=0
    fi
  done
  return "$found"
}

ensure_configs() {
  [[ -f "$SBOX_DIR/sb.json" ]] || die "Missing $SBOX_DIR/sb.json. Install sing-box-yg first."
  config_files >/dev/null || die "No sing-box config files found in $SBOX_DIR."
}

ensure_registry() {
  mkdir -p "$(dirname "$REGISTRY")"
  if [[ ! -f "$REGISTRY" ]]; then
    : >"$REGISTRY"
    chmod 600 "$REGISTRY" 2>/dev/null || true
  fi
}

validate_name() {
  local name="$1"
  [[ -n "$name" ]] || die "User name cannot be empty."
  [[ "$name" != *$'\t'* ]] || die "User name cannot contain tabs: $name"
  [[ "$name" != *$'\n'* ]] || die "User name cannot contain newlines: $name"
  [[ "$name" != */* ]] || die "User name cannot contain slash: $name"
}

safe_name() {
  local raw="$1"
  local fallback="${2:-user}"
  local safe
  safe=$(printf '%s' "$raw" | LC_ALL=C tr -c 'A-Za-z0-9_.@+-' '_')
  safe=${safe#_}
  safe=${safe%_}
  if [[ -z "$safe" ]]; then
    safe="$fallback"
  fi
  printf '%s\n' "$safe"
}

is_uuid() {
  [[ "$1" =~ ^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$ ]]
}

registry_has_name() {
  [[ -f "$REGISTRY" ]] || return 1
  awk -F '\t' -v name="$1" '$1 == name { found=1 } END { exit found ? 0 : 1 }' "$REGISTRY"
}

registry_has_uuid() {
  [[ -f "$REGISTRY" ]] || return 1
  awk -F '\t' -v id="$1" '$2 == id { found=1 } END { exit found ? 0 : 1 }' "$REGISTRY"
}

registry_lookup_uuid() {
  [[ -f "$REGISTRY" ]] || return 1
  awk -F '\t' -v q="$1" '($1 == q || $2 == q) { print $2; found=1; exit } END { exit found ? 0 : 1 }' "$REGISTRY"
}

registry_lookup_name() {
  [[ -f "$REGISTRY" ]] || return 1
  awk -F '\t' -v id="$1" '$2 == id { print $1; found=1; exit } END { exit found ? 0 : 1 }' "$REGISTRY"
}

append_registry() {
  local name="$1"
  local uuid="$2"
  local created_at="$3"
  ensure_registry
  printf '%s\t%s\t%s\n' "$name" "$uuid" "$created_at" >>"$REGISTRY"
  chmod 600 "$REGISTRY" 2>/dev/null || true
}

remove_registry_uuid() {
  local uuid="$1"
  local tmp
  [[ -f "$REGISTRY" ]] || return 0
  tmp=$(mktemp "${REGISTRY}.tmp.XXXXXX")
  awk -F '\t' -v id="$uuid" '$2 != id' "$REGISTRY" >"$tmp"
  chmod --reference="$REGISTRY" "$tmp" 2>/dev/null || true
  chown --reference="$REGISTRY" "$tmp" 2>/dev/null || true
  mv "$tmp" "$REGISTRY"
}

generate_uuid() {
  if [[ -x "$SBOX_DIR/sing-box" ]]; then
    "$SBOX_DIR/sing-box" generate uuid
  elif command -v sing-box >/dev/null 2>&1; then
    sing-box generate uuid
  elif command -v uuidgen >/dev/null 2>&1; then
    uuidgen | tr 'A-F' 'a-f'
  elif [[ -r /proc/sys/kernel/random/uuid ]]; then
    cat /proc/sys/kernel/random/uuid
  else
    die "Cannot generate UUID. Install sing-box or uuidgen."
  fi
}

uuid_exists_anywhere() {
  local uuid="$1"
  local file
  while IFS= read -r file; do
    if jq -e --arg id "$uuid" 'any(.inbounds[]?.users[]?; (.uuid? == $id) or (.password? == $id))' "$file" >/dev/null; then
      return 0
    fi
  done < <(config_files)
  return 1
}

new_unique_uuid() {
  local uuid
  local i
  for i in 1 2 3 4 5 6 7 8 9 10; do
    uuid=$(generate_uuid | tr -d '\r\n')
    if is_uuid "$uuid" && ! registry_has_uuid "$uuid" && ! uuid_exists_anywhere "$uuid"; then
      printf '%s\n' "$uuid"
      return 0
    fi
  done
  die "Failed to generate a unique UUID."
}

backup_configs() {
  local backup_dir
  local file
  backup_dir="$SBOX_DIR/backups/multi-user-$(date '+%Y%m%d-%H%M%S')-$$"
  mkdir -p "$backup_dir"
  while IFS= read -r file; do
    cp -a "$file" "$backup_dir/"
  done < <(config_files)
  printf '%s\n' "$backup_dir"
}

restore_configs() {
  local backup_dir="$1"
  local file
  local base
  for file in "$backup_dir"/*.json; do
    [[ -e "$file" ]] || continue
    base=$(basename "$file")
    cp -a "$file" "$SBOX_DIR/$base"
  done
}

add_uuid_to_file() {
  local file="$1"
  local uuid="$2"
  local tmp
  tmp=$(mktemp "${file}.multi.XXXXXX")
  if jq --arg id "$uuid" '
    def has_credential($id): any(.users[]?; (.uuid? == $id) or (.password? == $id));
    .inbounds = ((.inbounds // []) | map(
      if .tag == "vless-sb" then
        if has_credential($id) then . else .users = ((.users // []) + [{"uuid": $id, "flow": "xtls-rprx-vision"}]) end
      elif .tag == "vmess-sb" then
        if has_credential($id) then . else .users = ((.users // []) + [{"uuid": $id, "alterId": 0}]) end
      elif .tag == "hy2-sb" then
        if has_credential($id) then . else .users = ((.users // []) + [{"password": $id}]) end
      elif .tag == "tuic5-sb" then
        if has_credential($id) then . else .users = ((.users // []) + [{"uuid": $id, "password": $id}]) end
      elif .tag == "anytls-sb" then
        if has_credential($id) then . else .users = ((.users // []) + [{"password": $id}]) end
      else
        .
      end
    ))
  ' "$file" >"$tmp"; then
    chmod --reference="$file" "$tmp" 2>/dev/null || true
    chown --reference="$file" "$tmp" 2>/dev/null || true
    mv "$tmp" "$file"
  else
    rm -f "$tmp"
    return 1
  fi
}

remove_uuid_from_file() {
  local file="$1"
  local uuid="$2"
  local tmp
  tmp=$(mktemp "${file}.multi.XXXXXX")
  if jq --arg id "$uuid" '
    .inbounds = ((.inbounds // []) | map(
      if .tag == "vless-sb" or .tag == "vmess-sb" or .tag == "hy2-sb" or .tag == "tuic5-sb" or .tag == "anytls-sb" then
        .users = [(.users // [])[] | select(((.uuid? // "") != $id) and ((.password? // "") != $id))]
      else
        .
      end
    ))
  ' "$file" >"$tmp"; then
    chmod --reference="$file" "$tmp" 2>/dev/null || true
    chown --reference="$file" "$tmp" 2>/dev/null || true
    mv "$tmp" "$file"
  else
    rm -f "$tmp"
    return 1
  fi
}

add_uuid_to_configs() {
  local uuid="$1"
  local file
  while IFS= read -r file; do
    add_uuid_to_file "$file" "$uuid"
  done < <(config_files)
}

remove_uuid_from_configs() {
  local uuid="$1"
  local file
  while IFS= read -r file; do
    remove_uuid_from_file "$file" "$uuid"
  done < <(config_files)
}

find_sing_box() {
  if [[ -x "$SBOX_DIR/sing-box" ]]; then
    printf '%s\n' "$SBOX_DIR/sing-box"
  elif command -v sing-box >/dev/null 2>&1; then
    command -v sing-box
  fi
}

validate_config() {
  local bin
  bin=$(find_sing_box || true)
  if [[ -z "$bin" ]]; then
    warn "sing-box binary not found; skipped config check."
    return 0
  fi
  "$bin" check -c "$SBOX_DIR/sb.json"
}

restart_service() {
  if command -v systemctl >/dev/null 2>&1 && systemctl restart sing-box >/dev/null 2>&1; then
    info "Restarted sing-box with systemctl."
    return 0
  fi
  if command -v rc-service >/dev/null 2>&1 && rc-service sing-box restart >/dev/null 2>&1; then
    info "Restarted sing-box with rc-service."
    return 0
  fi
  if command -v service >/dev/null 2>&1 && service sing-box restart >/dev/null 2>&1; then
    info "Restarted sing-box with service."
    return 0
  fi
  warn "Could not restart sing-box automatically. Run: systemctl restart sing-box"
  return 1
}

resolve_uuid() {
  local target="$1"
  local uuid
  uuid=$(registry_lookup_uuid "$target" || true)
  if [[ -n "$uuid" ]]; then
    printf '%s\n' "$uuid"
    return 0
  fi
  if is_uuid "$target"; then
    printf '%s\n' "$target"
    return 0
  fi
  return 1
}

jget() {
  local tag="$1"
  local expr="$2"
  { jq -r --arg tag "$tag" '.inbounds[]? | select(.tag == $tag) | '"$expr"' // empty' "$SBOX_DIR/sb.json" | head -n 1; } 2>/dev/null || true
}

has_inbound() {
  jq -e --arg tag "$1" 'any(.inbounds[]?; .tag == $tag)' "$SBOX_DIR/sb.json" >/dev/null 2>&1
}

read_first() {
  local file="$1"
  if [[ -s "$file" ]]; then
    head -n 1 "$file"
  else
    return 1
  fi
}

argo_host() {
  local host
  host=$(read_first "$SBOX_DIR/sbargoym.log" 2>/dev/null || true)
  if [[ -z "$host" && -s "$SBOX_DIR/argo.log" ]]; then
    host=$(grep -a 'trycloudflare.com' "$SBOX_DIR/argo.log" 2>/dev/null | awk 'NR==2{print}' | awk -F// '{print $2}' | awk '{print $1}' || true)
  fi
  printf '%s\n' "$host"
}

vm_argo_link() {
  local name="$1"
  local uuid="$2"
  local tls_enabled
  local ws_path
  local host
  local add
  local label
  local safe
  local host_name

  has_inbound "vmess-sb" || return 1
  tls_enabled=$(jq -r '.inbounds[]? | select(.tag == "vmess-sb") | .tls.enabled' "$SBOX_DIR/sb.json" 2>/dev/null | head -n 1)
  [[ "$tls_enabled" == "false" ]] || return 1
  ws_path=$(jget "vmess-sb" ".transport.path")
  [[ -n "$ws_path" ]] || return 1
  host=$(argo_host)
  [[ -n "$host" ]] || return 1
  add="cloudflare-ech.com"
  if [[ -s "$SBOX_DIR/cfvmadd_argo.txt" ]]; then
    add=$(read_first "$SBOX_DIR/cfvmadd_argo.txt" || printf 'cloudflare-ech.com')
  fi
  host_name=$(hostname 2>/dev/null || printf 'sbox')
  safe=$(safe_name "$name" "$uuid")
  label="$host_name-$safe"
  vmess_link "$add" "$host" "$uuid" "$ws_path" "443" "vm-argo-$label" "tls" "$host"
}

server_ip_main() {
  local ip
  ip=$(read_first "$SBOX_DIR/server_ip.log" || true)
  if [[ -z "$ip" ]] && command -v curl >/dev/null 2>&1; then
    ip=$(curl -fsS4m 4 https://api.ipify.org 2>/dev/null || true)
  fi
  if [[ -z "$ip" ]] && command -v hostname >/dev/null 2>&1; then
    ip=$(hostname -I 2>/dev/null | awk '{print $1}' || true)
  fi
  printf '%s\n' "${ip:-YOUR_SERVER_IP}"
}

server_ip_client() {
  local ip
  ip=$(read_first "$SBOX_DIR/server_ipcl.log" || true)
  if [[ -z "$ip" ]]; then
    ip=$(server_ip_main)
  fi
  printf '%s\n' "$ip"
}

ca_domain() {
  read_first "/root/ygkkkca/ca.log" 2>/dev/null || true
}

sha256_pin() {
  if [[ -f "$SBOX_DIR/cert.pem" ]] && command -v openssl >/dev/null 2>&1 && command -v sha256sum >/dev/null 2>&1; then
    openssl x509 -in "$SBOX_DIR/cert.pem" -outform DER 2>/dev/null | sha256sum | awk '{print $1}' || true
  fi
}

b64_one_line() {
  if base64 --help 2>&1 | grep -q -- '-w'; then
    base64 -w 0
  else
    base64 | tr -d '\n'
  fi
}

vmess_link() {
  local add="$1"
  local host="$2"
  local uuid="$3"
  local path="$4"
  local port="$5"
  local ps="$6"
  local tls="$7"
  local sni="$8"
  local json
  local encoded
  json=$(jq -cn \
    --arg add "$add" \
    --arg host "$host" \
    --arg uuid "$uuid" \
    --arg path "$path" \
    --arg port "$port" \
    --arg ps "$ps" \
    --arg tls "$tls" \
    --arg sni "$sni" \
    '{add:$add, aid:"0", host:$host, id:$uuid, net:"ws", path:$path, port:$port, ps:$ps, tls:$tls, type:"none", v:"2"} +
     (if $tls == "tls" then {sni:$sni, fp:"chrome"} else {} end)')
  encoded=$(printf '%s' "$json" | b64_one_line)
  printf 'vmess://%s\n' "$encoded"
}

build_links() {
  local name="$1"
  local uuid="$2"
  local server_ip
  local server_ipcl
  local label
  local host_name
  local safe

  server_ip=$(server_ip_main)
  server_ipcl=$(server_ip_client)
  host_name=$(hostname 2>/dev/null || printf 'sbox')
  safe=$(safe_name "$name" "$uuid")
  label="$host_name-$safe"

  printf '# user: %s\n' "$name"
  printf '# uuid/password: %s\n' "$uuid"
  printf '# generated_at: %s\n\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')"

  if has_inbound "vless-sb"; then
    local vl_port vl_name public_key short_id
    vl_port=$(jget "vless-sb" ".listen_port")
    vl_name=$(jget "vless-sb" ".tls.server_name")
    short_id=$(jget "vless-sb" ".tls.reality.short_id[0]")
    public_key=$(read_first "$SBOX_DIR/public.key" || true)
    if [[ -n "$vl_port" && -n "$vl_name" && -n "$public_key" && -n "$short_id" ]]; then
      printf 'vless://%s@%s:%s?encryption=none&flow=xtls-rprx-vision&security=reality&sni=%s&fp=chrome&pbk=%s&sid=%s&type=tcp&headerType=none#vl-reality-%s\n' \
        "$uuid" "$server_ip" "$vl_port" "$vl_name" "$public_key" "$short_id" "$label"
    fi
  fi

  if has_inbound "vmess-sb"; then
    local vm_port ws_path tls_enabled vm_name vm_add vm_host vm_tls vm_sni
    vm_port=$(jget "vmess-sb" ".listen_port")
    ws_path=$(jget "vmess-sb" ".transport.path")
    tls_enabled=$(jget "vmess-sb" ".tls.enabled")
    vm_name=$(jget "vmess-sb" ".tls.server_name")
    if [[ "$tls_enabled" == "true" ]]; then
      vm_add="$vm_name"
      vm_host="$vm_name"
      vm_tls="tls"
      vm_sni="$vm_name"
    else
      vm_add="$server_ip"
      vm_host="$vm_name"
      vm_tls=""
      vm_sni=""
      if [[ -s "$SBOX_DIR/cfymjx.txt" ]]; then
        vm_host=$(read_first "$SBOX_DIR/cfymjx.txt" || true)
      fi
    fi
    if [[ -s "$SBOX_DIR/cfvmadd_local.txt" ]]; then
      vm_add=$(read_first "$SBOX_DIR/cfvmadd_local.txt" || true)
    fi
    if [[ -n "$vm_port" && -n "$ws_path" && -n "$vm_add" ]]; then
      vmess_link "$vm_add" "$vm_host" "$uuid" "$ws_path" "$vm_port" "vm-ws-$label" "$vm_tls" "$vm_sni"
    fi
    vm_argo_link "$name" "$uuid" || true
  fi

  if has_inbound "hy2-sb"; then
    local hy2_port hy2_key hy2_sni hy2_add pin pin_arg
    hy2_port=$(jget "hy2-sb" ".listen_port")
    hy2_key=$(jget "hy2-sb" ".tls.key_path")
    if [[ "$hy2_key" == "$SBOX_DIR/private.key" ]]; then
      hy2_sni="www.bing.com"
      hy2_add="$server_ip"
      pin=$(sha256_pin)
      pin_arg=""
      [[ -n "$pin" ]] && pin_arg="&pinSHA256=$pin"
    else
      hy2_sni=$(ca_domain)
      hy2_add="$hy2_sni"
      pin_arg=""
    fi
    if [[ -n "$hy2_port" && -n "$hy2_add" && -n "$hy2_sni" ]]; then
      printf 'hysteria2://%s@%s:%s?security=tls&alpn=h3&insecure=0&allowInsecure=0%s&sni=%s#hy2-%s\n' \
        "$uuid" "$hy2_add" "$hy2_port" "$pin_arg" "$hy2_sni" "$label"
    fi
  fi

  if has_inbound "tuic5-sb"; then
    local tuic_port tuic_key tuic_sni tuic_add tuic_insecure tuic_pin tuic_pin_arg
    tuic_port=$(jget "tuic5-sb" ".listen_port")
    tuic_key=$(jget "tuic5-sb" ".tls.key_path")
    if [[ "$tuic_key" == "$SBOX_DIR/private.key" ]]; then
      tuic_sni="www.bing.com"
      tuic_add="$server_ip"
      tuic_pin=$(sha256_pin)
      if [[ -n "$tuic_pin" ]]; then
        tuic_pin_arg="&pinnedPeerCertSha256=$tuic_pin"
        tuic_insecure=""
      else
        tuic_insecure="1"
        tuic_pin_arg=""
      fi
    else
      tuic_sni=$(ca_domain)
      tuic_add="$tuic_sni"
      tuic_insecure="0"
      tuic_pin_arg=""
    fi
    if [[ -n "$tuic_port" && -n "$tuic_add" && -n "$tuic_sni" ]]; then
      if [[ -n "$tuic_pin_arg" ]]; then
        printf 'tuic://%s:%s@%s:%s?congestion_control=bbr&udp_relay_mode=native&alpn=h3&sni=%s%s#tu5-%s\n' \
          "$uuid" "$uuid" "$tuic_add" "$tuic_port" "$tuic_sni" "$tuic_pin_arg" "$label"
      else
        printf 'tuic://%s:%s@%s:%s?congestion_control=bbr&udp_relay_mode=native&alpn=h3&sni=%s&insecure=%s&allowInsecure=%s&allow_insecure=%s#tu5-%s\n' \
          "$uuid" "$uuid" "$tuic_add" "$tuic_port" "$tuic_sni" "$tuic_insecure" "$tuic_insecure" "$tuic_insecure" "$label"
      fi
    fi
  fi

  if has_inbound "anytls-sb"; then
    local an_port an_key an_sni an_add an_insecure
    an_port=$(jget "anytls-sb" ".listen_port")
    an_key=$(jget "anytls-sb" ".tls.key_path")
    if [[ "$an_key" == "$SBOX_DIR/private.key" ]]; then
      an_sni="www.bing.com"
      an_add="$server_ip"
      an_insecure="1"
    else
      an_sni=$(ca_domain)
      an_add="$an_sni"
      an_insecure="0"
    fi
    if [[ -n "$an_port" && -n "$an_add" && -n "$an_sni" ]]; then
      printf 'anytls://%s@%s:%s?sni=%s&allowInsecure=%s&insecure=%s#anytls-%s\n' \
        "$uuid" "$an_add" "$an_port" "$an_sni" "$an_insecure" "$an_insecure" "$label"
    fi
  fi
}

emit_links() {
  local name="$1"
  local uuid="$2"
  local safe
  local outfile
  local argo_outfile
  local argo_link
  safe=$(safe_name "$name" "$uuid")
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    mkdir -p "$USER_DIR"
    outfile="$USER_DIR/$safe.txt"
    build_links "$name" "$uuid" | tee "$outfile"
    info "Saved links to $outfile"
    argo_link=$(vm_argo_link "$name" "$uuid" || true)
    if [[ -n "$argo_link" ]]; then
      argo_outfile="$SBOX_DIR/vm_argo_user_$safe.txt"
      printf '%s\n' "$argo_link" >"$argo_outfile"
      chmod 600 "$argo_outfile" 2>/dev/null || true
      info "Saved vm-argo link to $argo_outfile"
    fi
  else
    build_links "$name" "$uuid"
  fi
}

ensure_no_duplicate_args() {
  local a b count
  for a in "$@"; do
    count=0
    for b in "$@"; do
      if [[ "$a" == "$b" ]]; then
        count=$((count + 1))
      fi
    done
    [[ "$count" -eq 1 ]] || die "Duplicate user in arguments: $a"
  done
}

cmd_add() {
  local backup_dir
  local created_file
  local name uuid created_at

  need_root "$@"
  require_cmd jq
  ensure_configs
  ensure_registry
  [[ "$#" -gt 0 ]] || die "Usage: sudo bash $0 add alice [bob ...]"
  ensure_no_duplicate_args "$@"

  for name in "$@"; do
    validate_name "$name"
    registry_has_name "$name" && die "User already exists in registry: $name"
  done

  backup_dir=$(backup_configs)
  created_file=$(mktemp "/tmp/sbox-users-created.XXXXXX")

  for name in "$@"; do
    uuid=$(new_unique_uuid)
    if ! add_uuid_to_configs "$uuid"; then
      restore_configs "$backup_dir"
      rm -f "$created_file"
      die "Failed to update configs. Restored backup: $backup_dir"
    fi
    created_at=$(date '+%Y-%m-%dT%H:%M:%S%z')
    printf '%s\t%s\t%s\n' "$name" "$uuid" "$created_at" >>"$created_file"
  done

  if ! validate_config; then
    restore_configs "$backup_dir"
    rm -f "$created_file"
    die "sing-box config check failed. Restored backup: $backup_dir"
  fi

  while IFS=$'\t' read -r name uuid created_at; do
    append_registry "$name" "$uuid" "$created_at"
  done <"$created_file"

  restart_service || true

  while IFS=$'\t' read -r name uuid created_at; do
    printf '\n'
    info "Created user: $name"
    info "Credential: $uuid"
    emit_links "$name" "$uuid"
  done <"$created_file"

  rm -f "$created_file"
  info "Backup saved at $backup_dir"
}

cmd_remove() {
  local backup_dir
  local removed_file
  local target uuid name safe

  need_root "$@"
  require_cmd jq
  ensure_configs
  [[ "$#" -gt 0 ]] || die "Usage: sudo bash $0 remove alice|uuid [bob|uuid ...]"
  ensure_no_duplicate_args "$@"

  removed_file=$(mktemp "/tmp/sbox-users-removed.XXXXXX")

  for target in "$@"; do
    uuid=$(resolve_uuid "$target" || true)
    if [[ -z "$uuid" ]]; then
      rm -f "$removed_file"
      die "Unknown user or UUID: $target"
    fi
    name=$(registry_lookup_name "$uuid" || true)
    [[ -n "$name" ]] || name="$target"
    printf '%s\t%s\t%s\n' "$target" "$uuid" "$name" >>"$removed_file"
  done

  backup_dir=$(backup_configs)

  while IFS=$'\t' read -r target uuid name; do
    if ! remove_uuid_from_configs "$uuid"; then
      restore_configs "$backup_dir"
      rm -f "$removed_file"
      die "Failed to update configs. Restored backup: $backup_dir"
    fi
  done <"$removed_file"

  if ! validate_config; then
    restore_configs "$backup_dir"
    rm -f "$removed_file"
    die "sing-box config check failed. Restored backup: $backup_dir"
  fi

  while IFS=$'\t' read -r target uuid name; do
    remove_registry_uuid "$uuid"
  done <"$removed_file"

  restart_service || true

  while IFS=$'\t' read -r target uuid name; do
    info "Removed credential for $target: $uuid"
    safe=$(safe_name "$name" "$uuid")
    rm -f "$USER_DIR/$safe.txt" "$SBOX_DIR/vm_argo_user_$safe.txt"
  done <"$removed_file"

  rm -f "$removed_file"
  info "Backup saved at $backup_dir"
}

cmd_list() {
  ensure_configs
  if [[ -s "$REGISTRY" ]]; then
    printf 'Registered users:\n'
    awk -F '\t' '{ printf "  %-20s %s  %s\n", $1, $2, $3 }' "$REGISTRY"
  else
    printf 'Registered users: none\n'
  fi

  if command -v jq >/dev/null 2>&1; then
    printf '\nCurrent inbound user counts:\n'
    jq -r '
      .inbounds[]?
      | select(.tag == "vless-sb" or .tag == "vmess-sb" or .tag == "hy2-sb" or .tag == "tuic5-sb" or .tag == "anytls-sb")
      | "  \(.tag): \((.users // []) | length)"
    ' "$SBOX_DIR/sb.json"
  fi
}

cmd_links() {
  local target="${1:-}"
  local uuid
  local name

  require_cmd jq
  ensure_configs
  [[ -n "$target" ]] || die "Usage: bash $0 links alice|uuid"
  uuid=$(resolve_uuid "$target" || true)
  [[ -n "$uuid" ]] || die "Unknown user or UUID: $target"
  name=$(registry_lookup_name "$uuid" || true)
  [[ -n "$name" ]] || name="$target"
  emit_links "$name" "$uuid"
}

cmd_check() {
  ensure_configs
  validate_config
}

main() {
  local cmd="${1:-}"
  if [[ -z "$cmd" || "$cmd" == "-h" || "$cmd" == "--help" ]]; then
    usage
    exit 0
  fi
  shift || true
  case "$cmd" in
    add|create)
      cmd_add "$@"
      ;;
    remove|rm|delete)
      cmd_remove "$@"
      ;;
    list|ls)
      cmd_list "$@"
      ;;
    links|link|show)
      cmd_links "$@"
      ;;
    check)
      cmd_check "$@"
      ;;
    *)
      usage
      die "Unknown command: $cmd"
      ;;
  esac
}

main "$@"
