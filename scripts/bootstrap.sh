#!/usr/bin/env bash
# ------------------------------------------------------------------
# Provision an ARM64 Ubuntu host (Oracle Cloud Ampere A1) for
# Project Ampere. Idempotent — safe to re-run.
#
#   sudo scripts/bootstrap.sh
# ------------------------------------------------------------------
set -euo pipefail

log() { printf '[bootstrap] %s\n' "$*"; }
die() { printf '[bootstrap] ERROR: %s\n' "$*" >&2; exit 1; }

# System packages required by the three servers.
REQUIRED_PKGS=(
  docker.io
  docker-compose-v2
  screen
  wget
  curl
  jq
  git
  ca-certificates
  unzip
  tar
  xz-utils
)

require_root() {
  [ "$(id -u)" -eq 0 ] || die "run me as root (sudo scripts/bootstrap.sh)"
}

install_packages() {
  log "installing system packages"
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y
  apt-get install -y "${REQUIRED_PKGS[@]}"
}

enable_docker() {
  log "enabling Docker"
  systemctl enable --now docker
  # Allow the ubuntu user to drive the compose/containers without sudo.
  usermod -aG docker ubuntu 2>/dev/null || true
}

print_next_steps() {
  cat <<'EOF'

Done. Next:
  1. Clone this repo to /home/ubuntu/servers.
  2. For each server, copy the *.example.* config to the real location
     and fill in your secrets (tokens, webhooks, passwords).
  3. Open ports in the OCI Network Security List:
       25565/tcp               Minecraft
       34197/udp + 34198/tcp   Factorio (game / RCON)
       7777 + 8888 (udp+tcp)   Satisfactory
     plus outbound 443/tcp for SteamCMD and Discord webhooks.
EOF
}

main() {
  log "provisioning host for Project Ampere"
  require_root
  install_packages
  enable_docker
  print_next_steps
}

main "$@"