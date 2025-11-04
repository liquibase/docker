# Official Liquibase Docker Images

## 🚨 Important: Liquibase 5.0 Changes 🚨

### Liquibase Community vs Liquibase Secure

Starting with **Liquibase 5.0**, we have introduced a clear separation between our open source Community edition and our commercial Secure offering:

- **`liquibase/liquibase`** (Community Edition): Community version under the Functional Source License (FSL)
- **`liquibase/liquibase-secure`** (Secure Edition): Commercial version with enterprise features

**If you have a valid Liquibase License Key, you should now use `liquibase/liquibase-secure` instead of `liquibase/liquibase`.**

### 📋 Image Availability Matrix

| Version Range | Community Image | Secure Image | License | Docker Official |
|---|---|---|---|---|
| **5.0.0+** | `liquibase/liquibase` | `liquibase/liquibase-secure` | FSL* / Commercial | ✅ Yes** (`liquibase:5.0.1`) |
| **4.27.0 - 4.x** | `liquibase/liquibase` | `liquibase/liquibase-secure` | Apache 2.0 / Commercial | ✅ Yes*** (`liquibase:4.x`) |
| **< 4.27.0** | `liquibase/liquibase` | Limited availability | Apache 2.0 | N/A |

*FSL = Functional Source License (See [Liquibase License Information](#license-information))
**For 5.0+, the official Docker image is available at [https://hub.docker.com/\_/liquibase](https://hub.docker.com/_/liquibase). Pull using `docker pull liquibase:5.0.1` (official format) or `docker pull liquibase/liquibase:5.0.1` (community registry).
***4.27.0+ is available as the official image at [https://hub.docker.com/\_/liquibase](https://hub.docker.com/_/liquibase). Pull using `docker pull liquibase:4.27.0` (official format) or `docker pull liquibase/liquibase:4.27.0` (community registry).

### 🚨 Breaking Change: Drivers and Extensions No Longer Included

As of **Liquibase 5.0**, the Community edition (`liquibase/liquibase`) **no longer includes database drivers or extensions by default**.

**What this means for you:**

- You must now explicitly add database drivers using the Liquibase Package Manager (LPM)
- Extensions must be manually installed or mounted into the container
- MySQL driver installation via `INSTALL_MYSQL=true` environment variable is still supported

**Learn more:** [Liquibase 5.0 Release Announcement](https://www.liquibase.com/blog/liquibase-5-0-release)

### Adding Drivers with LPM

```dockerfile
FROM liquibase/liquibase:latest
# Add database drivers as needed
RUN lpm add mysql --global
RUN lpm add postgresql --global
RUN lpm add mssql --global
```

---

## 🌍 Available Registries

We publish Liquibase images to multiple registries for flexibility:

| Registry                      | Community Image                      | Secure Image                                |
| ----------------------------- | ------------------------------------ | ------------------------------------------- |
| **Docker Hub (default)**      | `liquibase/liquibase`                | `liquibase/liquibase-secure`                |
| **GitHub Container Registry** | `ghcr.io/liquibase/liquibase`        | `ghcr.io/liquibase/liquibase-secure`        |
| **Amazon ECR Public**         | `public.ecr.aws/liquibase/liquibase` | `public.ecr.aws/liquibase/liquibase-secure` |

## 🚀 Quick Start

### For Community Users (Liquibase 5.0+)

```bash
# Pull the community image
docker pull liquibase/liquibase:5.0.1

# Run with a changelog
docker run --rm \
  -v /path/to/changelog:/liquibase/changelog \
  -e LIQUIBASE_COMMAND_URL="jdbc:postgresql://localhost:5432/mydb" \
  -e LIQUIBASE_COMMAND_USERNAME="username" \
  -e LIQUIBASE_COMMAND_PASSWORD="password" \
  liquibase/liquibase update
```

### For Secure Edition Users

```bash
# Pull the latest secure image
docker pull liquibase/liquibase-secure:latest

# Run with a changelog and license key
docker run --rm \
  -v /path/to/changelog:/liquibase/changelog \
  -e LIQUIBASE_COMMAND_URL="jdbc:postgresql://localhost:5432/mydb" \
  -e LIQUIBASE_COMMAND_USERNAME="username" \
  -e LIQUIBASE_COMMAND_PASSWORD="password" \
  -e LIQUIBASE_LICENSE_KEY="your-license-key" \
  liquibase/liquibase-secure update
```

### For Liquibase 4.x Users (Legacy)

If you're still using Liquibase 4.x, you can use the official image or community registry:

```bash
# Pull from official image (recommended)
docker pull liquibase:4.27.0

# OR pull from community registry
docker pull liquibase/liquibase:4.27.0
```

---

## 📖 Upgrading from Liquibase 4.x to 5.0

If you're upgrading from Liquibase 4.x to 5.0, follow these steps:

### Step 1: Understand License Requirements

- **Liquibase 4.x**: Uses Apache 2.0 license (always available)
- **Liquibase 5.0 Community**: Uses Functional Source License (FSL)
- **Liquibase 5.0 Secure**: Requires a commercial license

Read more: [Liquibase License Information](#license-information)

### Step 2: Determine Which Edition You Need

**Use Community Edition if:**
- You are an open source user
- You accept the Functional Source License terms
- You do not require enterprise features

**Use Secure Edition if:**
- You have a commercial Liquibase license
- You need enterprise features like Policy Checks, Quality Checks, or Advanced Rollback
- Your organization requires commercial support

### Step 3: Update Your Image Reference

**If using Community Edition (Official Image - Recommended):**

```bash
# Before (4.x)
FROM liquibase:4.27.0

# After (5.0+)
FROM liquibase:5.0.1  # or :latest
```

**If using Community Edition (Community Registry - Alternative):**

```bash
# Before (4.x)
FROM liquibase/liquibase:4.27.0

# After (5.0+)
FROM liquibase/liquibase:5.0.1  # or :latest
```

**If using Secure Edition:**

```bash
# Before (if available)
FROM liquibase/liquibase-secure:4.27.0

# After (5.0+)
FROM liquibase/liquibase-secure:5.0.1  # or :latest
```

### Step 4: Update Driver Installation

**Liquibase 5.0+ no longer includes drivers by default.** Add drivers explicitly:

```dockerfile
FROM liquibase/liquibase:latest

# Add required database drivers
RUN lpm add postgresql --global
RUN lpm add mysql --global
RUN lpm add mssql --global
```

Or at runtime using environment variables:

```bash
docker run -e INSTALL_MYSQL=true liquibase/liquibase:latest update
```

### Step 5: Test in Non-Production First

```bash
# Test your changelogs against a test database
docker run --rm \
  -v /path/to/changelog:/liquibase/changelog \
  -e LIQUIBASE_COMMAND_URL="jdbc:postgresql://test-db:5432/testdb" \
  -e LIQUIBASE_COMMAND_USERNAME="username" \
  -e LIQUIBASE_COMMAND_PASSWORD="password" \
  liquibase/liquibase:5.0.0 validate
```

### Step 6: Complete Production Migration

Once testing is successful, update your production deployments to use the new image.

---

## 🔐 License Information

### Functional Source License (FSL) - Liquibase 5.0 Community

The Liquibase 5.0 Community edition is available under the Functional Source License (FSL). This license:

- Allows you to freely use Liquibase for database migrations
- Is limited to organizations with less than $50M in annual revenue
- Includes automatic transition to Apache 2.0 after 4 years
- Provides full source code access

**For organizations exceeding the revenue threshold or requiring unrestricted use, please consider the Liquibase Secure edition.**

Read the full license: [Functional Source License on fsl.software](https://fsl.software/)

### Apache 2.0 License - Liquibase 4.x

Liquibase 4.x versions continue to use the Apache 2.0 license, which is unrestricted for any organization size.

### Commercial License - Liquibase Secure

The Liquibase Secure edition requires a commercial license and provides:
- Enterprise features (Policy Checks, Quality Checks)
- Priority support
- Advanced rollback capabilities
- Compliance features

For licensing inquiries, visit [liquibase.com/get-liquibase](https://www.liquibase.com/get-liquibase)

---

## Dockerfile

```dockerfile
FROM liquibase:latest
# OR ghcr.io/liquibase/liquibase:latest    # GHCR
# OR public.ecr.aws/liquibase/liquibase:latest   # Amazon ECR Public
```

## Scripts

### Community Edition

```bash
# Docker Hub (default)
docker pull liquibase/liquibase

# GitHub Container Registry
docker pull ghcr.io/liquibase/liquibase

# Amazon ECR Public
docker pull public.ecr.aws/liquibase/liquibase
```

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

#### Community Edition

```bash
# Latest
docker pull liquibase/liquibase:latest
docker pull ghcr.io/liquibase/liquibase:latest
docker pull public.ecr.aws/liquibase/liquibase:latest

# Specific version (example: 4.32.0)
docker pull liquibase/liquibase:4.32.0
docker pull ghcr.io/liquibase/liquibase:4.32.0
docker pull public.ecr.aws/liquibase/liquibase:4.32.0
```

#### Liquibase Secure Edition

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

---

This is the community repository for [Liquibase](https://download.liquibase.org/) images.

## 🚨 BREAKING CHANGE

Support for Snowflake database has been moved from the external extension liquibase-snowflake into the main Liquibase artifact. This means that Snowflake is now included in the main docker image. If you are using the snowflake extension, remove it from your lib directory or however you are including it in your project. If you are using the Docker image, use the main v4.12+ as there will no longer be a snowflake separate docker image produced. The latest separate Snowflake image will be v4.11. You need to update your reference to either latest to use the main one that includes Snowflake or the version tag you prefer. <https://github.com/liquibase/liquibase/pull/2841>

## 🏷️ Image Tags and Versions

Liquibase Docker images use semantic versioning with the following tag strategies:

### Tag Formats

| Tag Format | Example | Description |
|---|---|---|
| `latest` | `liquibase/liquibase:latest` | Latest stable release |
| `latest-alpine` | `liquibase/liquibase:latest-alpine` | Latest stable Alpine variant |
| `<version>` | `liquibase/liquibase:5.0.0` | Specific version (exact match) |
| `<version>-alpine` | `liquibase/liquibase:5.0.0-alpine` | Specific Alpine version |
| `<major>.<minor>` | `liquibase/liquibase:5.0` | Latest patch for major.minor |
| `<major>` | `liquibase/liquibase:5` | Latest patch for major version |

### Community vs Secure Image Tags

The same tag structure applies to both image types:

- **Community**: `liquibase/liquibase:5.0.0`
- **Secure**: `liquibase/liquibase-secure:5.0.0`

Both are available across all registries (Docker Hub, GHCR, Amazon ECR Public).

### Supported Tags

The following tags are officially supported and can be found on [Docker Hub](https://hub.docker.com/r/liquibase/liquibase/tags):

**Community Image:**
- `liquibase/liquibase:latest` - Latest 5.0+ release
- `liquibase/liquibase:5` - Latest 5.x release
- `liquibase/liquibase:5.0` - Latest 5.0.x release
- `liquibase/liquibase:5.0.0` - Specific version
- `liquibase/liquibase:latest-alpine` - Latest Alpine variant
- `liquibase/liquibase:4.27.0` - 4.x versions (Apache 2.0)

**Secure Image:**
- `liquibase/liquibase-secure:latest` - Latest Secure release
- `liquibase/liquibase-secure:5.0.0` - Specific Secure version
- `liquibase/liquibase-secure:latest-alpine` - Latest Secure Alpine variant

### Choosing the Right Tag

- **For production**: Use specific version tags (`5.0.0`) for reproducibility
- **For development**: Use `latest` or `latest-alpine` for convenience
- **For Alpine Linux**: Append `-alpine` for smaller image size
- **For Liquibase 4.x**: Use `4.27.0` or other 4.x specific versions (Apache 2.0 license)

## 📦 Using the Docker Image

### 🏷️ Standard Image

The `liquibase/liquibase:<version>` image is the standard choice. Use it as a disposable container or a foundational building block for other images.

For examples of extending the standard image, see the [standard image examples](https://github.com/liquibase/docker/tree/main/examples).

### 🏷️ Alpine Image

The `liquibase/liquibase:<version>-alpine` image is a lightweight version designed for environments with limited resources. It is built on Alpine Linux and has a smaller footprint.

For examples of extending the alpine image, see the [alpine image examples](https://github.com/liquibase/docker/tree/main/examples).

### 🐳 Docker Compose Example

For a complete example using Docker Compose with PostgreSQL, see the [docker-compose example](https://github.com/liquibase/docker/tree/main/examples/docker-compose).

### 📄 Using the Changelog File

Mount your changelog directory to the `/liquibase/changelog` volume and use relative paths for the `--changeLogFile` argument.

#### Example

```shell
docker run --rm -v /path/to/changelog:/liquibase/changelog liquibase/liquibase --changeLogFile=changelog.xml update
```

### 🔄 CLI-Docker Compatibility

Starting with this version, Docker containers now behave consistently with CLI usage for file path handling. When you mount your changelog directory to `/liquibase/changelog`, the container automatically changes its working directory to match, making relative file paths work the same way in both CLI and Docker environments.

**Before this enhancement:**

- CLI: `liquibase generateChangeLog --changelogFile=mychangelog.xml` (creates file in current directory)
- Docker: `liquibase generateChangeLog --changelogFile=changelog/mychangelog.xml` (had to include path prefix)

**Now (improved):**

- CLI: `liquibase generateChangeLog --changelogFile=mychangelog.xml` (creates file in current directory)
- Docker: `liquibase generateChangeLog --changelogFile=mychangelog.xml` (creates file in mounted changelog directory)

Both approaches now work identically, making it easier to switch between local CLI and CI/CD Docker usage without modifying your commands or file paths.

#### How it works

When you mount a directory to `/liquibase/changelog`, the container automatically:

1. Detects the presence of the mounted changelog directory
2. Changes the working directory to `/liquibase/changelog`
3. Executes Liquibase commands from that location

This ensures that relative paths in your commands work consistently whether you're using CLI locally or Docker containers in CI/CD pipelines.

### ⚙️ Using a Configuration File

To use a default configuration file, mount it in your changelog volume and reference it with the `--defaultsFile` argument.

#### Example

```shell
docker run --rm -v /path/to/changelog:/liquibase/changelog liquibase/liquibase --defaultsFile=liquibase.properties update
```

### 📚 Including Drivers and Extensions

Mount a local directory containing additional jars to `/liquibase/lib`.

#### Example

```shell
docker run --rm -v /path/to/changelog:/liquibase/changelog -v /path/to/lib:/liquibase/lib liquibase/liquibase update
```

### 🔍 MySQL Users

Due to licensing restrictions, the MySQL driver is not included. Add it either by extending the image or during runtime via an environment variable.

#### Extending the Image

Dockerfile:

```dockerfile
FROM liquibase:latest

RUN lpm add mysql --global
```

Build:

```shell
docker build . -t liquibase-mysql
```

#### Runtime

```shell
docker run -e INSTALL_MYSQL=true liquibase/liquibase update
```

## 🛠️ Complete Example

Here is a complete example using environment variables and a properties file:

### Environment Variables Example

```shell
docker run --env LIQUIBASE_COMMAND_USERNAME --env LIQUIBASE_COMMAND_PASSWORD --env LIQUIBASE_COMMAND_URL --env LIQUIBASE_PRO_LICENSE_KEY --env LIQUIBASE_COMMAND_CHANGELOG_FILE --rm -v /path/to/changelog:/liquibase/changelog liquibase/liquibase --log-level=info update
```

### Properties File Example

`liquibase.docker.properties` file:

```properties
searchPath: /liquibase/changelog
url: jdbc:postgresql://<IP OR HOSTNAME>:5432/<DATABASE>?currentSchema=<SCHEMA NAME>
changeLogFile: changelog.xml
username: <USERNAME>
password: <PASSWORD>
liquibaseSecureLicenseKey=<PASTE LB Secure LICENSE KEY HERE>
```

CLI:

```shell
docker run --rm -v /path/to/changelog:/liquibase/changelog liquibase/liquibase --defaultsFile=liquibase.docker.properties update
```

## 🔗 Example JDBC URLs

- MS SQL Server: `jdbc:sqlserver://<IP OR HOSTNAME>:1433;database=<DATABASE>`
- PostgreSQL: `jdbc:postgresql://<IP OR HOSTNAME>:5432/<DATABASE>?currentSchema=<SCHEMA NAME>`
- MySQL: `jdbc:mysql://<IP OR HOSTNAME>:3306/<DATABASE>`
- MariaDB: `jdbc:mariadb://<IP OR HOSTNAME>:3306/<DATABASE>`
- DB2: `jdbc:db2://<IP OR HOSTNAME>:50000/<DATABASE>`
- Snowflake: `jdbc:snowflake://<IP OR HOSTNAME>/?db=<DATABASE>&schema=<SCHEMA NAME>`
- Sybase: `jdbc:jtds:sybase://<IP OR HOSTNAME>:/<DATABASE>`
- SQLite: `jdbc:sqlite:/tmp/<DB FILE NAME>.db`

For more details, visit our [Liquibase Documentation](https://docs.liquibase.com/).

<img referrerpolicy="no-referrer-when-downgrade" src="https://static.scarf.sh/a.png?x-pxid=fc4516b5-fc01-40ce-849b-f97dd7be2a34" />
