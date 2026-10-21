#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

NAVIDROME_WAS_RUNNING=false

if [[ -n "$(docker compose ps --status running -q navidrome)" ]]; then
    NAVIDROME_WAS_RUNNING=true
fi

restart_navidrome() {
    if [[ "$NAVIDROME_WAS_RUNNING" == true ]]; then
        echo "Starting Navidrome..."
        docker compose start navidrome || {
            echo "WARNING: Navidrome could not be restarted automatically."
            return 1
        }
    fi
}

trap restart_navidrome EXIT

if [[ "$NAVIDROME_WAS_RUNNING" == true ]]; then
    echo "Stopping Navidrome for a consistent backup..."
    docker compose stop navidrome
fi

echo "Creating Restic backup..."
docker compose --profile backup run --rm restic backup /source/navidrome

echo "Restarting Navidrome..."
restart_navidrome
trap - EXIT

echo "Applying seven-day retention policy..."
docker compose --profile backup run --rm restic \
    forget --keep-daily 7 --prune

echo "Checking Restic repository..."
docker compose --profile backup run --rm restic check

echo "Backup completed successfully."
