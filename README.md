# MediaHub

A personal DevOps and automation project focused on building and maintaining a self-hosted environment for services related to my hobbies, including anime, manga, music, books and gaming.

The main goal is to explore and apply DevOps practices by automating infrastructure configuration, application deployment and ongoing maintenance.

## Objectives

- Automate repetitive tasks and workflows.
- Manage services using containerization.
- Implement CI/CD pipelines for validation and testing.
- Use version control and configuration as code.
- Improve service monitoring and reliability.
- Implement backups and recovery procedures.
- Apply security best practices.
- Document the setup and configuration to ensure reproducibility.

## Technologies

The project currently uses or explores technologies related to:

- Linux and systems administration
- Docker Compose and containerization
- Git and GitHub
- GitHub Actions for CI validation
- Prometheus and Grafana for monitoring and alerting
- Restic for encrypted backups
- Shell scripting and configuration as code

Additional technologies may be introduced as the project develops.

## Project Structure

The repository contains service configurations, automation scripts, CI/CD configuration and documentation. Its structure evolves alongside the project.

The current personal setup runs on WSL with Ubuntu. Environment-specific settings are configured through a `.env` file, with `.env.example` documenting the required variables without exposing secrets.

## Architecture and Design Decisions

MediaHub uses Docker Compose to manage its services in a shared container network. This keeps deployment configuration in one place and makes it straightforward to start, stop and maintain the environment.

### Service deployment

**Navidrome** provides music streaming from a local music library. The library is mounted into the container as read-only, while Navidrome's application data is stored separately to preserve its configuration and state.

**Jellyfin** provides media streaming from a local video library through a web interface and compatible clients. The media directory is mounted into the container as read-only, while its configuration and cache are stored separately to preserve application settings and runtime data.

Persistent application data is kept outside the Git repository. Configuration files are version-controlled so that the setup can be reproduced without committing application data or secrets.

### Monitoring and alerting

Prometheus collects metrics from Navidrome and Jellyfin and monitors their availability. It also collects its own metrics.

Navidrome exposes metrics through its configured `/metrics_mediahub` endpoint, while Jellyfin exposes metrics through its `/metrics` endpoint.

Grafana uses Prometheus as its data source to display service metrics through provisioned dashboards. Separate dashboards are used for Navidrome and Jellyfin.

Grafana alert rules detect when Navidrome becomes unavailable or its expected metrics are missing. Dashboard, data source and alert configurations are stored in the repository so they can be provisioned automatically when Grafana starts.

### Backup and recovery

Restic runs in a dedicated Docker Compose service to back up Navidrome's application data, excluding the music library.

- **Storage:** A local Restic repository inside the WSL filesystem.
- **Security:** Encrypted backups, with the repository password stored outside Git.
- **Retention:** Keeps seven daily snapshots, removing older snapshots according to the configured retention policy.
- **Verification:** The backup script checks repository integrity after creating a backup and applying retention.
- **Execution:** Backups are currently run manually through `scripts/backup.sh`. Scheduling is left for future development.

The backup process is kept separate from the main service deployment so backup operations can be run when needed without adding another always-running container.

Jellyfin's configuration and cache are stored separately, but automated backups for Jellyfin have not yet been configured.

### CI/CD and configuration management

GitHub Actions validates the Docker Compose configuration on pushes and pull requests. This catches configuration errors before changes are merged.

Environment-specific values are supplied through environment variables, while secrets and local paths remain outside version control. The current pipeline validates configuration rather than deploying changes automatically.

## Platforms and Services

### Navidrome

Navidrome hosts the local music library and provides access to music through a web interface and compatible clients.

- **Deployment:** Docker Compose
- **Default port:** `4533`
- **Monitoring:** Prometheus metrics
- **Backup:** Restic for application data

### Jellyfin

Jellyfin hosts the local video library and provides media streaming through a web interface and compatible clients.

- **Deployment:** Docker Compose
- **Default port:** `8096`
- **Media storage:** Local video library mounted read-only
- **Persistent data:** Configuration and cache stored separately
- **Monitoring:** Prometheus metrics exposed through `/metrics`
- **Backup:** Automated backups not yet configured

### Prometheus

Prometheus collects and stores service metrics. It is configured to scrape its own metrics and those exposed by Navidrome and Jellyfin.

### Grafana

Grafana provides dashboards and alerting based on Prometheus metrics. Its dashboard, data source and alert rules are provisioned from repository configuration.

### Restic

Restic provides encrypted backups of Navidrome's application data. The backup workflow is managed through `scripts/backup.sh`.

Run a backup:

```bash
./scripts/backup.sh
```

List snapshots:

```bash
docker compose --profile backup run --rm restic snapshots
```

## Current Status

MediaHub is an ongoing personal project. The current setup includes music and video streaming through Navidrome and Jellyfin, Prometheus monitoring, Grafana dashboards, availability alerting, encrypted backups for Navidrome and CI configuration validation.

Further development will focus on improving the existing setup where useful, documenting operational procedures and exploring additional automation without introducing unnecessary complexity.

## Goals

The project aims to provide a practical environment for developing skills in systems engineering, DevOps and automation while building something useful for personal use.

The emphasis is on reproducibility, maintainability, reliability, security and reducing manual intervention through automation.