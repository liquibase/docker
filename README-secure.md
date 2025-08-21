# Official Liquibase-Secure Docker Images

**Liquibase Secure** is the enterprise edition of Liquibase that provides advanced database DevOps capabilities for teams requiring enhanced security, performance, and governance features.

## ⚠️ License Requirements

> **WARNING**: Liquibase Secure requires a valid license key to use Secure features. Without a license, the container will run in Liquibase Community mode with limited functionality.
>
> - Contact [Liquibase Sales](https://www.liquibase.com/community/contact) to obtain a Liquibase Secure license
> - Existing customers receive their Secure license keys in an email.

## 📋 Secure Features

Liquibase Secure is the enterprise edition of [Liquibase](https://www.liquibase.com/) that provides advanced database DevOps capabilities for teams requiring enhanced security, performance, and governance features.

Liquibase Secure includes all Community features plus:

### 🔐 Security & Governance

- **Policy Checks**: Enforce database standards and best practices
- **Quality Checks**: Advanced validation rules for changesets  
- **Rollback SQL**: Generate rollback scripts for any deployment
- **Targeted Rollback**: Rollback specific changesets without affecting others
- **Advanced Database Support**: Enhanced support for Oracle, SQL Server, and other enterprise databases
- **Audit Reports**: Comprehensive tracking of database changes
- **Stored Logic**: Support for functions, procedures, packages, and triggers

## 🔧 Environment Variables

### Secure License Environment Variable

| Variable | Description | Example |
|----------|-------------|---------|
| `LIQUIBASE_LICENSE_KEY` | Your Liquibase Secure license key | `ABcd-1234-EFGH-5678` |

### 🔧 Action Required

Please update your Dockerfiles and scripts to pull from the new official image:

## Available Registries

We publish this image to multiple registries:

| Registry | Secure Image |
|----------|-----------|
| **Docker Hub (default)** | `liquibase/liquibase-secure` |
| **GitHub Container Registry** | `ghcr.io/liquibase/liquibase-secure` |
| **Amazon ECR Public** | `public.ecr.aws/liquibase/liquibase-secure` |

## Dockerfile

```dockerfile
FROM liquibase/liquibase-secure:latest
# OR ghcr.io/liquibase/liquibase-secure:latest    # GHCR  
# OR public.ecr.aws/liquibase/liquibase-secure:latest   # Amazon ECR Public
```

## Scripts

### Liquibase Secure Edition

```bash
# Docker Hub (default)
docker pull liquibase/liquibase-secure

# GitHub Container Registry
docker pull ghcr.io/liquibase/liquibase-secure

# Amazon ECR Public
docker pull public.ecr.aws/liquibase/liquibase-secure
```

### Pulling the Latest or Specific Version

#### Pulling Liquibase Secure Edition Images

```bash
# Latest
docker pull liquibase/liquibase-secure:latest
docker pull ghcr.io/liquibase/liquibase-secure:latest
docker pull public.ecr.aws/liquibase/liquibase-secure:latest

# Specific version (example: 4.32.0)
docker pull liquibase/liquibase-secure:4.32.0
docker pull ghcr.io/liquibase/liquibase-secure:4.32.0
docker pull public.ecr.aws/liquibase/liquibase-secure:4.32.0
```

For any questions or support, please visit our [Liquibase Community Forum](https://forum.liquibase.org/).

## 🏷️ Supported Tags

The following tags are officially supported and can be found on [Docker Hub](https://hub.docker.com/r/liquibase/liquibase-secure/tags):

- `liquibase/liquibase-secure:<version>`

### Database Connection Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `LIQUIBASE_COMMAND_URL` | Database JDBC URL | `jdbc:postgresql://db:5432/mydb` |
| `LIQUIBASE_COMMAND_USERNAME` | Database username | `dbuser` |
| `LIQUIBASE_COMMAND_PASSWORD` | Database password | `dbpass` |
| `LIQUIBASE_COMMAND_CHANGELOG_FILE` | Path to changelog file | `/liquibase/changelog/changelog.xml` |

### Liquibase Secure-Specific Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `LIQUIBASE_SECURE_POLICY_CHECKS_ENABLED` | Enable policy checks | `true` |
| `LIQUIBASE_SECURE_QUALITY_CHECKS_ENABLED` | Enable quality checks | `true` |
| `LIQUIBASE_REPORTS_ENABLED` | Enable HTML reports | `true` |
| `LIQUIBASE_REPORTS_PATH` | Reports output directory | `/tmp/reports` |

## Required License Configuration

Set your Liquibase Secure license key using the `LIQUIBASE_LICENSE_KEY` environment variable:

```bash
$ docker run --rm \
    -e LIQUIBASE_LICENSE_KEY="YOUR_LICENSE_KEY_HERE" \
    -v /path/to/changelog:/liquibase/changelog \
    liquibase/liquibase-secure \
    --changelog-file=example-changelog.xml \
    --url="jdbc:postgresql://host.docker.internal:5432/testdb" \
    --username=postgres \
    --password=password \
    --search-path=/liquibase/changelog/ \
    update
```

## Mounting Changelog Files

Mount your changelog directory to the `/liquibase/changelog` volume and use the `--search-path` parameter to specify the location.

```bash
$ docker run --rm \
    -e LIQUIBASE_LICENSE_KEY="YOUR_LICENSE_KEY_HERE" \
    -v "$(pwd)":/liquibase/changelog \
    liquibase/liquibase-secure \
    --changelog-file=example-changelog.xml \
    --search-path=/liquibase/changelog/ \
    update
```

## Using a Properties File

To use a default configuration file, mount it in your changelog volume and reference it with the `--defaults-file` argument.

```bash
$ docker run --rm \
    -e LIQUIBASE_LICENSE_KEY="YOUR_LICENSE_KEY_HERE" \
    -v /path/to/changelog:/liquibase/changelog \
    liquibase/liquibase-secure \
    --defaults-file=liquibase.properties update
```

Example `liquibase.properties` file:

```bash
url=jdbc:postgresql://host.docker.internal:5432/testdb
username=postgres
password=password
changelog-file=example-changelog.xml
search-path=/liquibase/changelog/
licenseKey=<PASTE LB SECURE LICENSE KEY HERE>
```

## Adding Additional JARs

Mount a local directory containing additional jars to `/liquibase/lib`.

```bash
$ docker run --rm \
    -e LIQUIBASE_LICENSE_KEY="YOUR_LICENSE_KEY_HERE" \
    -v /path/to/changelog:/liquibase/changelog \
    -v /path/to/lib:/liquibase/lib \
    liquibase/liquibase-secure update

## 📦 Using the Docker Image

### 🏷️ Standard Image

The `liquibase/liquibase-secure:<version>` image is the standard choice. Use it as a disposable container or a foundational building block for other images.

For examples of extending the standard image, see the [standard image examples](https://github.com/liquibase/docker/tree/main/examples).


**Usage:**

```bash
# Build the image
docker build . -t liquibase-secure-aws

# Run with AWS credentials
docker run --rm \
  -e AWS_ACCESS_KEY_ID="your-access-key" \
  -e AWS_SECRET_ACCESS_KEY="your-secret-key" \
  -e LIQUIBASE_LICENSE_KEY="your-license-key" \
  -v "$(pwd)":/liquibase/changelog \
  liquibase-secure-aws \
  --changelog-file=changelog.xml \
  --search-path=/liquibase/changelog/ \
  update
```

### 🐳 Docker Compose Example

For a complete example using Docker Compose with PostgreSQL:

```yaml
version: '3.8'
services:
  liquibase:
    image: liquibase/liquibase-secure:latest
    environment:
      LIQUIBASE_LICENSE_KEY: "${LIQUIBASE_LICENSE_KEY}"
      LIQUIBASE_COMMAND_URL: "jdbc:postgresql://postgres:5432/example"
      LIQUIBASE_COMMAND_USERNAME: "liquibase"
      LIQUIBASE_COMMAND_PASSWORD: "liquibase"
      LIQUIBASE_COMMAND_CHANGELOG_FILE: "changelog.xml"
    volumes:
      - ./changelog:/liquibase/changelog
    depends_on:
      - postgres
    command: update

  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: example
      POSTGRES_USER: liquibase
      POSTGRES_PASSWORD: liquibase
    ports:
      - "5432:5432"
```

## License

This Docker image contains Liquibase Secure software which requires a valid commercial license for use.

For licensing questions, please contact [Liquibase Sales](https://www.liquibase.com/contact).

View [license information](https://www.liquibase.com/eula) for the software contained in this image.

As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).

Some additional license information which was able to be auto-detected might be found in [the `repo-info` repository's `liquibase/` directory](https://github.com/docker-library/repo-info/tree/master/repos/liquibase).

As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.
