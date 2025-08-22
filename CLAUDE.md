# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is the official Liquibase Docker image repository that builds and publishes Docker images for both Liquibase OSS and Liquibase Pro editions. The repository contains:

- **Dockerfile**: Standard Liquibase OSS image
- **DockerfilePro**: Liquibase Pro image with enterprise features
- **Dockerfile.alpine**: Alpine Linux variant (lightweight)
- **Examples**: Database-specific extensions (AWS CLI, SQL Server, PostgreSQL, Oracle)
- **Docker Compose**: Complete example with PostgreSQL

## Image Publishing

Images are published to multiple registries:
- Docker Hub: `liquibase/liquibase` (OSS) and `liquibase/liquibase-pro` (Pro)
- GitHub Container Registry: `ghcr.io/liquibase/liquibase*`
- Amazon ECR Public: `public.ecr.aws/liquibase/liquibase*`

## Common Development Commands

### Building Images

```bash
# Build OSS image
docker build -f Dockerfile -t liquibase/liquibase:latest .

# Build Pro image
docker build -f DockerfilePro -t liquibase/liquibase-pro:latest .

# Build Alpine variant
docker build -f Dockerfile.alpine -t liquibase/liquibase:latest-alpine .
```

### Testing Images

```bash
# Test OSS image
docker run --rm liquibase/liquibase:latest --version

# Test Pro image (requires license)
docker run --rm -e LIQUIBASE_LICENSE_KEY="your-key" liquibase/liquibase-pro:latest --version

# Run with example changelog
docker run --rm -v $(pwd)/examples/docker-compose/changelog:/liquibase/changelog liquibase/liquibase:latest --changelog-file=db.changelog-master.xml validate
```

### Docker Compose Example

```bash
# Run complete example with PostgreSQL
cd examples/docker-compose
docker-compose up

# Use local build for testing
docker-compose -f docker-compose.local.yml up --build
```

## Architecture

### Base Image Structure
- **Base**: Eclipse Temurin JRE 21 (Jammy)
- **User**: Non-root `liquibase` user (UID/GID 1001)
- **Working Directory**: `/liquibase`
- **Entrypoint**: `docker-entrypoint.sh` with automatic MySQL driver installation

### Key Components
- **Liquibase**: Database migration tool (OSS: GitHub releases, Pro: repo.liquibase.com)
- **LPM**: Liquibase Package Manager for extensions
- **Default Config**: `liquibase.docker.properties` sets headless mode
- **CLI-Docker Compatibility**: Auto-detects `/liquibase/changelog` mount and changes working directory for consistent behavior

### Version Management
- Liquibase versions are controlled via `LIQUIBASE_VERSION` (OSS) and `LIQUIBASE_PRO_VERSION` (Pro) ARGs
- SHA256 checksums are validated for security
- LPM version is specified via `LPM_VERSION` ARG

## Environment Variables

### Database Connection
- `LIQUIBASE_COMMAND_URL`: JDBC connection string
- `LIQUIBASE_COMMAND_USERNAME`: Database username
- `LIQUIBASE_COMMAND_PASSWORD`: Database password
- `LIQUIBASE_COMMAND_CHANGELOG_FILE`: Path to changelog file

### Pro Features (DockerfilePro only)
- `LIQUIBASE_LICENSE_KEY`: Required for Pro features
- `LIQUIBASE_PRO_POLICY_CHECKS_ENABLED`: Enable policy checks
- `LIQUIBASE_PRO_QUALITY_CHECKS_ENABLED`: Enable quality checks

### Special Options
- `INSTALL_MYSQL=true`: Auto-install MySQL driver at runtime
- `LIQUIBASE_HOME=/liquibase`: Liquibase installation directory
- `DOCKER_LIQUIBASE=true`: Marker for Docker environment
- `SHOULD_CHANGE_DIR`: Override automatic working directory detection (true/false). When set, prevents the entrypoint from guessing whether to change to `/liquibase/changelog` directory based on command arguments

## Extending Images

### Adding Database Drivers
```dockerfile
FROM liquibase/liquibase:latest
RUN lpm add mysql --global
```

### Adding Tools (e.g., AWS CLI)
```dockerfile
FROM liquibase/liquibase:latest
USER root
RUN apt-get update && apt-get install -y awscli
USER liquibase
```

## Maven Configuration

The `pom.xml` is minimal and used for build processes. The repository primarily uses Docker for builds rather than Maven.