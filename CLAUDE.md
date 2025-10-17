# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is the official Liquibase Docker image repository that builds and publishes Docker images for both Liquibase OSS and Liquibase Secure editions. The repository contains:

- **Dockerfile**: Standard Liquibase OSS image
- **DockerfileSecure**: Liquibase Secure image (enterprise features)
- **Dockerfile.alpine**: Alpine Linux variant (lightweight)
- **Examples**: Database-specific extensions (AWS CLI, SQL Server, PostgreSQL, Oracle)
- **Docker Compose**: Complete example with PostgreSQL

## Image Publishing

Images are published to multiple registries:
- Docker Hub: `liquibase/liquibase` (OSS) and `liquibase/liquibase-secure` (Secure)
- GitHub Container Registry: `ghcr.io/liquibase/liquibase*`
- Amazon ECR Public: `public.ecr.aws/liquibase/liquibase*`

### Release Tagging Strategy

The repository uses distinct tagging strategies for OSS and SECURE releases to prevent conflicts:

**OSS Releases** (from `liquibase-release` workflow):
- Git tag: `v{version}` (e.g., `v5.0.1`)
- GitHub Release: `v{version}`
- Docker images: `liquibase/liquibase:{version}`, `liquibase/liquibase:{major.minor}`, `liquibase/liquibase:latest`

**SECURE Releases** (from `liquibase-secure-release` workflow):
- Git tag: `v{version}-SECURE` (e.g., `v5.0.1-SECURE`)
- GitHub Release: `v{version}-SECURE`
- Docker images: `liquibase/liquibase-secure:{version}`, `liquibase/liquibase-secure:{major.minor}`, `liquibase/liquibase-secure:latest`

This ensures that OSS and SECURE releases maintain separate version histories and do not create conflicting tags in Git or GitHub releases.

## Common Development Commands

### Building Images

```bash
# Build OSS image
docker build -f Dockerfile -t liquibase/liquibase:latest .

# Build Secure image
docker build -f DockerfileSecure -t liquibase/liquibase-secure:latest .

# Build Alpine variant
docker build -f Dockerfile.alpine -t liquibase/liquibase:latest-alpine .
```

### Testing Images

```bash
# Test OSS image
docker run --rm liquibase/liquibase:latest --version

# Test Secure image (requires license)
docker run --rm -e LIQUIBASE_LICENSE_KEY="your-key" liquibase/liquibase-secure:latest --version

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

# Run with Liquibase Secure
docker-compose -f docker-compose.secure.yml up
```

## Architecture

### Base Image Structure
- **Base**: Eclipse Temurin JRE 21 (Jammy)
- **User**: Non-root `liquibase` user (UID/GID 1001)
- **Working Directory**: `/liquibase`
- **Entrypoint**: `docker-entrypoint.sh` with automatic MySQL driver installation

### Key Components
- **Liquibase**: Database migration tool (OSS: GitHub releases, Secure: repo.liquibase.com)
- **LPM**: Liquibase Package Manager for extensions
- **Default Config**: `liquibase.docker.properties` sets headless mode
- **CLI-Docker Compatibility**: Auto-detects `/liquibase/changelog` mount and changes working directory for consistent behavior

### Version Management
- Liquibase versions are controlled via `LIQUIBASE_VERSION` (OSS) and `LIQUIBASE_PRO_VERSION` (Secure) ARGs
- SHA256 checksums are validated for security
- LPM version is specified via `LPM_VERSION` ARG

## Environment Variables

### Database Connection
- `LIQUIBASE_COMMAND_URL`: JDBC connection string
- `LIQUIBASE_COMMAND_USERNAME`: Database username
- `LIQUIBASE_COMMAND_PASSWORD`: Database password
- `LIQUIBASE_COMMAND_CHANGELOG_FILE`: Path to changelog file

### Secure Features (DockerfileSecure only)
- `LIQUIBASE_LICENSE_KEY`: Required for Secure features
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

### Using Liquibase Secure
```dockerfile
FROM liquibase/liquibase-secure:latest
ENV LIQUIBASE_LICENSE_KEY=your-license-key
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