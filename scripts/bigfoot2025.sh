#!/bin/bash
set -e
REPO="bigfoot2025"
APP_DIR="/opt/bigfoot"

notify_keeper() {
  curl -s -X POST https://keeper.deeptxai.com/api/cron/webhook     -H 'Content-Type: application/json'     -d "{\"jobName\":\"AutoDeploy: ${1}\",\"status\":\"ok\",\"output\":\"auto-deployed from GitHub push\",\"jobId\":\"autodeploy-${1}\"}" > /dev/null
}

echo "[deploy] $REPO starting..."
cd "$APP_DIR"
git fetch origin && git reset --hard origin/main
npm install --production
npm run build 2>/dev/null || true
sudo systemctl restart bigfoot
sudo systemctl restart bigfoot-backend
notify_keeper "$REPO"
echo "[deploy] $REPO done"
