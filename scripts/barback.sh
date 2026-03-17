#!/bin/bash
set -e
REPO="barback"
APP_DIR="/opt/barback"
SERVICE="barback"

notify_keeper() {
  curl -s -X POST https://keeper.deeptxai.com/api/cron/webhook \
    -H 'Content-Type: application/json' \
    -d "{\"jobName\":\"AutoDeploy: ${1}\",\"status\":\"ok\",\"output\":\"auto-deployed from GitHub push\",\"jobId\":\"autodeploy-${1}\"}" > /dev/null
}

echo "[deploy] $REPO starting..."
cd "$APP_DIR"
git fetch origin && git reset --hard origin/main
[ -f package.json ] && npm install --production
sudo systemctl restart "$SERVICE"
notify_keeper "$REPO"
echo "[deploy] $REPO done"
