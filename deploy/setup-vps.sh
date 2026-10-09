#!/usr/bin/env bash
# One-time setup on the VPS (Oracle Linux, user opc). Run with:  sudo bash deploy/setup-vps.sh <git-ssh-url>
#   e.g. sudo bash setup-vps.sh git@github.com:ijerimy/lts-website.git
# Safe to re-run.
set -euo pipefail

REPO_URL="${1:?Usage: sudo bash setup-vps.sh git@github.com:<owner>/<repo>.git}"
APP_DIR=/opt/lts-website
KEY=/root/.ssh/lts-website-deploy
BRANCH=main

[[ $EUID -eq 0 ]] || { echo "Run with sudo."; exit 1; }
command -v docker >/dev/null || { echo "Docker not found."; exit 1; }
docker compose version >/dev/null 2>&1 || { echo "Docker Compose v2 plugin not found (docker compose)."; exit 1; }
command -v git >/dev/null || dnf install -y git

# 1. Read-only deploy key for the private repo
mkdir -p /root/.ssh && chmod 700 /root/.ssh
if [[ ! -f $KEY ]]; then
  ssh-keygen -t ed25519 -N "" -C "lts-website deploy key ($(hostname))" -f "$KEY" >/dev/null
fi
grep -q "Host github-lts" /root/.ssh/config 2>/dev/null || cat >> /root/.ssh/config <<CFG
Host github-lts
  HostName github.com
  User git
  IdentityFile $KEY
  IdentitiesOnly yes
CFG
chmod 600 /root/.ssh/config
ssh-keyscan -t ed25519 github.com >> /root/.ssh/known_hosts 2>/dev/null
sort -u -o /root/.ssh/known_hosts /root/.ssh/known_hosts

# Rewrite git@github.com:owner/repo.git -> github-lts:owner/repo.git so it uses the deploy key
CLONE_URL="${REPO_URL/git@github.com:/github-lts:}"

if ! git ls-remote "$CLONE_URL" >/dev/null 2>&1; then
  echo
  echo "Add this as a READ-ONLY deploy key in GitHub:"
  echo "  Repo > Settings > Deploy keys > Add deploy key (leave 'Allow write access' unchecked)"
  echo
  cat "$KEY.pub"
  echo
  read -rp "Press Enter after adding it..."
  git ls-remote "$CLONE_URL" >/dev/null || { echo "Still can't reach the repo. Check the key and URL."; exit 1; }
fi

# 2. Clone (or update) the repo
if [[ -d $APP_DIR/.git ]]; then
  git -C "$APP_DIR" fetch --quiet origin "$BRANCH"
  git -C "$APP_DIR" reset --quiet --hard "origin/$BRANCH"
else
  git clone --quiet --branch "$BRANCH" "$CLONE_URL" "$APP_DIR"
fi

# 3. Find Nginx Proxy Manager's Docker network
NPM_CTR=$(docker ps --format '{{.Names}} {{.Image}}' | awk 'tolower($2) ~ /nginx-proxy-manager/ {print $1; exit}')
if [[ -z $NPM_CTR ]]; then
  echo "Couldn't find a running Nginx Proxy Manager container."
  docker network ls
  read -rp "Enter the Docker network NPM uses: " NPM_NETWORK
else
  NPM_NETWORK=$(docker inspect "$NPM_CTR" --format '{{range $k,$v := .NetworkSettings.Networks}}{{$k}} {{end}}' | awk '{print $1}')
  echo "NPM container: $NPM_CTR  network: $NPM_NETWORK"
fi
echo "NPM_NETWORK=$NPM_NETWORK" > "$APP_DIR/.env"

# 4. Build and start
cd "$APP_DIR" && docker compose up -d --build

# 5. Auto-update every 5 minutes
install -m 755 "$APP_DIR/deploy/update.sh" /usr/local/bin/lts-website-update
install -m 644 "$APP_DIR/deploy/lts-website-update.service" /etc/systemd/system/
install -m 644 "$APP_DIR/deploy/lts-website-update.timer" /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now lts-website-update.timer

echo
echo "Done. In Nginx Proxy Manager add a Proxy Host:"
echo "  Domain: lts.clarifiedtech.net   Scheme: http   Forward host: lts-website   Port: 8080"
echo "  SSL tab: request a Let's Encrypt cert, Force SSL on."
echo "Update log: journalctl -u lts-website-update -n 50"
