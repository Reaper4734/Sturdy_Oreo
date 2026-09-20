#!/usr/bin/env bash
set -e

# ==============================================================================
# OREO FULL-STACK DEPLOYMENT SCRIPT (EC2 + GITHUB)
# ==============================================================================

MESSAGE="${1:-Auto-commit and deploy updates}"
PEM_PATH="${2:-oreo-server.pem}"
HOST="${3:-oreo-api.duckdns.org}"
USER="${4:-ec2-user}"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

echo -e "\033[0;36m=================================================\033[0m"
echo -e "\033[0;36m         OREO FULL-STACK DEPLOYMENT PIPELINE      \033[0m"
echo -e "\033[0;36m=================================================\033[0m"

# 1. GitHub Push (Cloudflare Pages Frontend Trigger)
echo -e "\n\033[0;33m[1/2] Syncing repository with GitHub...\033[0m"
git -C "$DIR" add -A
if ! git -C "$DIR" diff --cached --quiet; then
    echo "Committing: '$MESSAGE'..."
    git -C "$DIR" commit -m "$MESSAGE"
fi
git -C "$DIR" push origin main
echo -e "\033[0;32m[OK] GitHub updated. Cloudflare Pages frontend build triggered!\033[0m"

# 2. EC2 Backend Deploy
echo -e "\n\033[0;33m[2/2] Deploying Backend to AWS EC2 ($HOST)...\033[0m"
chmod 400 "$DIR/$PEM_PATH" 2>/dev/null || true

TAR_FILE="$DIR/backend-deploy.tar.gz"
tar --exclude="build" --exclude=".gradle" --exclude="bin" --exclude=".env" -czf "$TAR_FILE" -C "$DIR/backend" .

scp -o ConnectTimeout=10 -o StrictHostKeyChecking=no -i "$DIR/$PEM_PATH" "$TAR_FILE" "${USER}@${HOST}:~/oreo/"
rm -f "$TAR_FILE"

ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -i "$DIR/$PEM_PATH" "${USER}@${HOST}" \
    "mkdir -p ~/oreo/backend && \
     tar -xzf ~/oreo/backend-deploy.tar.gz -C ~/oreo/backend && \
     rm -f ~/oreo/backend-deploy.tar.gz && \
     rm -f /home/ec2-user/.docker/cli-plugins/docker-buildx && \
     cd ~/oreo/backend && \
     docker-compose up -d --build backend"

echo -e "\n\033[0;32m[OK] AWS EC2 Backend successfully updated & running!\033[0m"
echo -e "\033[0;36m=================================================\033[0m"
echo -e "\033[0;32m            DEPLOYMENT COMPLETE!                 \033[0m"
echo -e "  Frontend: https://oreo.pages.dev"
echo -e "  Backend:  https://oreo-api.duckdns.org/api"
echo -e "\033[0;36m=================================================\033[0m"
