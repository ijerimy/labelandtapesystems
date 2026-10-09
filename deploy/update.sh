#!/usr/bin/env bash
# Pulls the latest commit and rebuilds the site only when something changed.
# Installed as /usr/local/bin/lts-website-update and run by lts-website-update.timer.
set -euo pipefail
APP_DIR=/opt/lts-website
BRANCH=main
cd "$APP_DIR"

git fetch --quiet origin "$BRANCH"
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse "origin/$BRANCH")

if [[ $LOCAL == "$REMOTE" && "${1:-}" != "--force" ]]; then
  exit 0
fi

echo "Updating $LOCAL -> $REMOTE"
git reset --quiet --hard "origin/$BRANCH"
# Keep the installed copy of this script current
install -m 755 deploy/update.sh /usr/local/bin/lts-website-update
docker compose up -d --build
docker image prune -f >/dev/null
echo "Now running $(git log -1 --format='%h %s')"
