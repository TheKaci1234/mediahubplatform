#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

echo "Validating Docker Compose configuration..."
docker compose config -q

echo "Deploying MediaHub services..."
docker compose up -d

echo "Deployment status:"
docker compose ps
