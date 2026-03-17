#!/bin/bash
set -e
REPO="MoPAutomation"
APP_DIR="/opt/mop"

notify_keeper() {
  curl -s -X POST https://keeper.deeptxai.com/api/cron/webhook     -H 'Content-Type: application/json'     -d "{\"jobName\":\"AutoDeploy: ${1}\",\"status\":\"ok\",\"output\":\"auto-deployed from GitHub push\",\"jobId\":\"autodeploy-${1}\"}" > /dev/null
}

echo "[deploy] $REPO starting..."
cd "$APP_DIR"
git fetch origin && git reset --hard origin/main
[ -f requirements.txt ] && pip3 install -r requirements.txt -q
sudo systemctl restart mop
notify_keeper "$REPO"
echo "[deploy] $REPO done"
