# Official Liquibase Enterprise Docker Images

**Liquibase Enterprise** (formerly Datical DB) is the enterprise edition of Liquibase that provides advanced database DevOps capabilities for teams managing complex database changes at scale with project-based deployments.

## Quick Start

### On x86-64 / AMD64 (Linux, Intel Mac, AMD)

```bash
# Pull the latest version
docker pull liquibase/liquibase-enterprise:latest

# Show version (requires license file)
docker run --rm \
  -v /path/to/license.lic:/liquibase/license/license.lic \
  liquibase/liquibase-enterprise:latest \
  show version
```

### On Apple Silicon (M1/M2/M3/M4)

```bash
# Pull the latest version
docker pull liquibase/liquibase-enterprise:latest

# Show version (requires --platform flag for Rosetta emulation)
docker run --rm --platform linux/amd64 \
  -v /path/to/license.lic:/liquibase/license/license.lic \
  liquibase/liquibase-enterprise:latest \
  show version
```

**Example output:**
```
Liquibase Enterprise CLI  8.10
  Component Versions:
          Liquibase Enterprise Core  8.10.479
          Liquibase Enterprise CLI   8.10.479.20250717040249
          Liquibase                  3.5.11640
          Stored Logic extension     1.0.318.20250710062909
          AppDBA extension           1.0.474.20250710061826
          Java                       11.0.15
```

## ⚠️ License Requirements

> **WARNING**: Liquibase Enterprise requires a valid license file to use Enterprise features. Without a license file, the container will not function properly.
>
> - Contact [Liquibase Sales](https://www.liquibase.com/contact-us) to obtain a Liquibase Enterprise license
> - Existing customers receive their Enterprise license files via email or through their account portal

## 📋 Enterprise Features

Liquibase Enterprise is the enterprise edition of [Liquibase](https://www.liquibase.com/) that provides advanced database DevOps capabilities with project-based deployment management.

Liquibase Enterprise includes all Community features plus:

### 🚀 Enterprise Capabilities

- **Deployment Packager**: Package database changes from source control for deployment across environments
- **Forecast & Deploy**: Preview changes before deployment and execute with confidence
- **Stored Logic Support**: Full support for functions, procedures, packages, and triggers
- **Database Comparison**: Compare schemas across environments
- **Advanced Rollback**: Sophisticated rollback capabilities for complex deployments
- **Project-Based Management**: Organize database changes in projects with environment-specific configurations
- **Hammer CLI**: Powerful command-line interface for all Enterprise operations
- **Change Monitoring**: Track and audit all database changes across your pipeline

### 🗄️ Included Database Drivers

The Docker image includes JDBC drivers for the following databases:

| Database | Driver Package |
|----------|----------------|
| **PostgreSQL** | `com.datical.db.drivers.postgres` |
| **SQL Server** | `com.datical.db.drivers.mssql` |
| **Oracle** | `com.datical.db.drivers.oracle` |
| **DB2** | `com.datical.db.drivers.db2` |

These drivers are pre-installed and ready to use. No additional driver installation is required.

### 🔧 Hammer Command

The primary interface for Liquibase Enterprise is the `hammer` command, which provides:

- `statusDetails` - Show deployment status for an environment
- `forecast` - Preview changes before deployment
- `deploy` - Execute deployments to target environments
- `deployPlan` - Deploy specific plans or labels
- `snapshot` - Capture current database schema state
- `diff` - Compare schemas between environments
- And many more enterprise operations

## 🔧 Environment Variables

### License Configuration

Liquibase Enterprise requires a license file to be mounted at runtime:

| Mount Point | Description | Required |
|-------------|-------------|----------|
| `/liquibase/license/license.lic` | License file location (preferred) | Yes |

### Project Configuration

| Volume | Description | Example |
|--------|-------------|---------|
| `/liquibase/project` | Liquibase Enterprise project directory | Your project with datical.project file |
| `/liquibase/src` | Source SQL files for Packager | SQL scripts from source control |

### Database Connection Variables (via project configuration)

Liquibase Enterprise uses project-based configuration stored in `datical.project` files. Database connections are configured per environment within your project.

## Available Registries

We publish this image to multiple registries:

| Registry | Enterprise Image |
|----------|------------------|
| **Docker Hub (default)** | `liquibase/liquibase-enterprise` |
| **GitHub Container Registry** | `ghcr.io/liquibase/liquibase-enterprise` |
| **Amazon ECR Public** | `public.ecr.aws/liquibase/liquibase-enterprise` |

## Dockerfile

```dockerfile
FROM liquibase/liquibase-enterprise:latest
# OR ghcr.io/liquibase/liquibase-enterprise:latest    # GHCR
# OR public.ecr.aws/liquibase/liquibase-enterprise:latest   # Amazon ECR Public
```

## Scripts

### Liquibase Enterprise Edition

```bash
# Docker Hub (default)
docker pull liquibase/liquibase-enterprise

# GitHub Container Registry
docker pull ghcr.io/liquibase/liquibase-enterprise

# Amazon ECR Public
docker pull public.ecr.aws/liquibase/liquibase-enterprise
```

### Pulling the Latest or Specific Version

#### Pulling Liquibase Enterprise Edition Images

```bash
# Latest
docker pull liquibase/liquibase-enterprise:latest
docker pull ghcr.io/liquibase/liquibase-enterprise:latest
docker pull public.ecr.aws/liquibase/liquibase-enterprise:latest

# Specific version (example: 8.10.479)
docker pull liquibase/liquibase-enterprise:8.10.479
docker pull ghcr.io/liquibase/liquibase-enterprise:8.10.479
docker pull public.ecr.aws/liquibase/liquibase-enterprise:8.10.479
```

For any questions or support, please visit our [Liquibase Support](https://forum.liquibase.org/).

## 🏷️ Supported Tags

The following tags are officially supported and can be found on [Docker Hub](https://hub.docker.com/r/liquibase/liquibase-enterprise/tags):

- `liquibase/liquibase-enterprise:<version>`
- `liquibase/liquibase-enterprise:<major.minor>`
- `liquibase/liquibase-enterprise:latest`

## 🛠️ Building the Image Locally

### Prerequisites

- Docker or Docker Desktop installed
- Access to software.datical.com to download the Liquibase Enterprise installer

### Build for Your Platform

```bash
# Build for current platform (ARM64 on Apple Silicon, AMD64 on Intel/AMD)
docker build -f DockerfileEnterprise \
  --build-arg ENTERPRISE_VERSION=8.10.479 \
  -t liquibase/liquibase-enterprise:local \
  .
```

### Build for Specific Platform

```bash
# Build for AMD64 (Intel/AMD) - Required for production Linux servers
docker buildx build --platform linux/amd64 \
  -f DockerfileEnterprise \
  --build-arg ENTERPRISE_VERSION=8.10.479 \
  -t liquibase/liquibase-enterprise:amd64 \
  --load \
  .

# Build for ARM64 (Apple Silicon, ARM servers)
docker buildx build --platform linux/arm64 \
  -f DockerfileEnterprise \
  --build-arg ENTERPRISE_VERSION=8.10.479 \
  -t liquibase/liquibase-enterprise:arm64 \
  --load \
  .
```

### Build Multi-Platform Image

```bash
# Build for both AMD64 and ARM64
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -f DockerfileEnterprise \
  --build-arg ENTERPRISE_VERSION=8.10.479 \
  -t liquibase/liquibase-enterprise:multiarch
  .
```

### Build Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `ENTERPRISE_VERSION` | Liquibase Enterprise version to install | `8.10.479` |

### Build Time

The build process typically takes 5-10 seconds, with most time spent on the IzPack installation process.

## Required License Configuration

Mount your Liquibase Enterprise license file to `/liquibase/license/`:

```bash
docker run --rm \
    -v /path/to/license.lic:/liquibase/license/license.lic \
    -v /path/to/project:/liquibase/project \
    liquibase/liquibase-enterprise \
    statusDetails DEV
```

## Mounting Project Files

Mount your Liquibase Enterprise project directory to the `/liquibase/project` volume:

```bash
docker run --rm \
    -v /path/to/license.lic:/liquibase/license/license.lic \
    -v "$(pwd)/my-project":/liquibase/project \
    liquibase/liquibase-enterprise \
    statusDetails PRODUCTION
```

Your project directory should contain:
- `datical.project` - Project configuration file
- `Changelog/` - Generated changelogs
- `Reports/` - Deployment reports
- `Resources/` - SQL scripts and resources

## Common Usage Examples

### Check Status

```bash
docker run --rm \
    -v /path/to/license.lic:/liquibase/license/license.lic \
    -v "$(pwd)/project":/liquibase/project \
    liquibase/liquibase-enterprise \
    statusDetails DEV
```

### Forecast Changes

```bash
docker run --rm \
    -v /path/to/license.lic:/liquibase/license/license.lic \
    -v "$(pwd)/project":/liquibase/project \
    liquibase/liquibase-enterprise \
    forecast PRODUCTION
```

### Deploy to Environment

```bash
docker run --rm \
    -v /path/to/license.lic:/liquibase/license/license.lic \
    -v "$(pwd)/project":/liquibase/project \
    liquibase/liquibase-enterprise \
    deploy PRODUCTION
```

### Run Packager (with source code)

```bash
docker run --rm \
    -v /path/to/license.lic:/liquibase/license/license.lic \
    -v "$(pwd)/project":/liquibase/project \
    -v "$(pwd)/sql-source":/liquibase/src \
    liquibase/liquibase-enterprise \
    groovy deployPackager.groovy pipeline=myPipeline scm=true
```

### Show Version

```bash
docker run --rm \
    -v /path/to/license.lic:/liquibase/license/license.lic \
    liquibase/liquibase-enterprise \
    show version
```

### Interactive Shell

```bash
docker run --rm -it \
    -v /path/to/license.lic:/liquibase/license/license.lic \
    -v "$(pwd)/project":/liquibase/project \
    liquibase/liquibase-enterprise \
    bash
```

## 🍎 Running on Apple Silicon (M1/M2/M3)

The Liquibase Enterprise installer includes x86-64 binaries. To run on Apple Silicon, you need to use the `--platform` flag:

```bash
# Show version on Apple Silicon
docker run --rm --platform linux/amd64 \
    -v /path/to/license.lic:/liquibase/license/license.lic \
    liquibase/liquibase-enterprise:latest \
    hammer show version

# Run with project on Apple Silicon
docker run --rm --platform linux/amd64 \
    -v /path/to/license.lic:/liquibase/license/license.lic \
    -v "$(pwd)/project":/liquibase/project \
    liquibase/liquibase-enterprise:latest \
    statusDetails DEV
```

**Note**: The `--platform linux/amd64` flag enables Rosetta translation on Apple Silicon Macs. For best performance in production, deploy to native x86-64 Linux servers.

## 📦 Using the Docker Image

### 🏷️ Standard Image

The `liquibase/liquibase-enterprise:<version>` image is the standard choice. Use it as a disposable container or a foundational building block for other images.

For examples of extending the standard image, see the [standard image examples](https://github.com/liquibase/docker/tree/main/examples).

### Extending the Image

You can extend the base image to add additional database clients or tools:

**Example: Adding PostgreSQL Client**

```dockerfile
FROM liquibase/liquibase-enterprise:latest

USER root
RUN apt-get update && \
    apt-get install -y postgresql-client && \
    rm -rf /var/lib/apt/lists/*
USER liquibase
```

**Example: Adding SQL Server Tools**

```dockerfile
FROM liquibase/liquibase-enterprise:latest

USER root
RUN apt-get update && \
    apt-get install -y curl apt-transport-https && \
    curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
    curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list > /etc/apt/sources.list.d/mssql-release.list && \
    apt-get update && \
    ACCEPT_EULA=Y apt-get install -y mssql-tools unixodbc-dev && \
    rm -rf /var/lib/apt/lists/*
ENV PATH="$PATH:/opt/mssql-tools/bin"
USER liquibase
```

### 🐳 Docker Compose Example

For a complete example using Docker Compose with PostgreSQL, see the [docker-compose.enterprise.yml](examples/docker-compose/docker-compose.enterprise.yml) file.

```yaml
version: '3.8'
services:
  liquibase:
    image: liquibase/liquibase-enterprise:latest
    volumes:
      - ./project:/liquibase/project
      - ./license.lic:/liquibase/license/license.lic
    command: ["statusDetails", "DEV"]
    depends_on:
      - postgres

  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: example
      POSTGRES_USER: liquibase
      POSTGRES_PASSWORD: liquibase
    ports:
      - "5432:5432"
```

## Using in CI/CD Pipelines

### Jenkins Example

```groovy
pipeline {
    agent any

    stages {
        stage('Deploy Database Changes') {
            steps {
                script {
                    docker.image('liquibase/liquibase-enterprise:latest').inside(
                        "-v ${WORKSPACE}/project:/liquibase/project " +
                        "-v ${LICENSE_FILE}:/liquibase/license/license.lic"
                    ) {
                        sh 'hammer forecast PRODUCTION'
                        sh 'hammer deploy PRODUCTION'
                    }
                }
            }
        }
    }
}
```

### GitLab CI Example

```yaml
deploy-database:
  image: liquibase/liquibase-enterprise:latest
  stage: deploy
  script:
    - hammer statusDetails PRODUCTION
    - hammer forecast PRODUCTION
    - hammer deploy PRODUCTION
  variables:
    LICENSE_FILE: /liquibase/license/license.lic
  artifacts:
    paths:
      - project/Reports/
```

### GitHub Actions Example

```yaml
- name: Deploy with Liquibase Enterprise
  run: |
    docker run --rm \
      -v ${{ github.workspace }}/project:/liquibase/project \
      -v ${{ github.workspace }}/license.lic:/liquibase/license/license.lic \
      liquibase/liquibase-enterprise:latest \
      deploy PRODUCTION
```

## Troubleshooting

### License File Not Found

If you see an error about a missing license file:

1. Ensure the license file is mounted to `/liquibase/license/license.lic` or `/liquibase/license/myLicense.lic`
2. Verify the license file exists and has correct permissions
3. Check that the license file is valid and not expired

### Project Not Found

If hammer cannot find your project:

1. Ensure your project directory is mounted to `/liquibase/project`
2. Verify the directory contains a `datical.project` file
3. Check file permissions allow the `liquibase` user (UID 1001) to read

### Command Not Found

The container defaults to running `hammer` commands. If you need to run bash or other commands:

```bash
docker run --rm -it \
    -v /path/to/license.lic:/liquibase/license/license.lic \
    -v "$(pwd)/project":/liquibase/project \
    liquibase/liquibase-enterprise \
    bash
```

### Rosetta Errors on Apple Silicon

If you see "rosetta error" messages on Apple Silicon:

1. Use the `--platform linux/amd64` flag when running the container
2. Ensure Docker Desktop is configured to use Rosetta for x86/amd64 emulation
3. For better performance, consider testing on native x86-64 Linux systems

### Architecture Compatibility

The Liquibase Enterprise installer includes x86-64 binaries. The image works best on:

- ✅ x86-64 Linux servers (production)
- ✅ Apple Silicon with `--platform linux/amd64` flag (development)
- ✅ ARM64 Linux with emulation

## License

This Docker image contains Liquibase Enterprise software which requires a valid commercial license for use.

For licensing questions, please contact [Liquibase Sales](https://www.liquibase.com/contact-us).

View [license information](https://www.datical.com/eula) for the software contained in this image.

As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).

As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.
