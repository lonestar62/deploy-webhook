#!/bin/bash
set -e
REPO="brain3"
APP_DIR="/opt/brain"
SERVICE="brain"

notify_keeper() {
  curl -s -X POST https://keeper.deeptxai.com/api/cron/webhook \
    -H 'Content-Type: application/json' \
    -d "{\"jobName\":\"AutoDeploy: ${1}\",\"status\":\"ok\",\"output\":\"auto-deployed from GitHub push\",\"jobId\":\"autodeploy-${1}\"}" > /dev/null
}

echo "[deploy] $REPO starting..."
cd "$APP_DIR"
git fetch origin && git reset --hard origin/main
[ -f package.json ] && npm install --production
npm run build
sudo systemctl restart "$SERVICE"
notify_keeper "$REPO"
echo "[deploy] $REPO done"
