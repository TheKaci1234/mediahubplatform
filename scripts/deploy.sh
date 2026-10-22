
#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

HEALTH_TIMEOUT=120
POLL_INTERVAL=5

echo "Validating Docker Compose configuration..."
docker compose config -q

echo "Deploying MediaHub services..."
docker compose up -d

echo "Waiting for containers to become healthy (timeout: ${HEALTH_TIMEOUT}s)..."

deadline=$((SECONDS + HEALTH_TIMEOUT))
failed=0

while (( SECONDS < deadline )); do
    failed=0
    pending=0

    while IFS= read -r container_id; do
        [[ -z "$container_id" ]] && continue

        details=$(docker inspect --format \
            '{{.Name}} {{.State.Status}} {{if .State.Health}}{{.State.Health.Status}}{{else}}no-healthcheck{{end}}' \
            "$container_id")

        read -r name status health <<< "$details"

        if [[ "$status" != "running" ]]; then
            echo "ERROR: ${name}: container status is ${status}"
            failed=1
            continue
        fi

        case "$health" in
            healthy|no-healthcheck)
                ;;
            unhealthy)
                echo "ERROR: ${name}: healthcheck failed"
                failed=1
                ;;
            starting)
                pending=1
                ;;
        esac
    done < <(docker compose ps -q)

    if (( failed )); then
        break
    fi

    if (( pending == 0 )); then
        break
    fi

    sleep "$POLL_INTERVAL"
done

echo
echo "Deployment status:"
docker compose ps

if (( failed )); then
    echo "ERROR: One or more containers failed."
    exit 1
fi

if (( pending )); then
    echo "ERROR: Timed out waiting for healthchecks."
    exit 1
fi

echo "MediaHub deployment checks completed."

