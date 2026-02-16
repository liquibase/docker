# Vulnerability Scanning Scripts

This directory contains shell scripts extracted from GitHub Actions workflows for vulnerability scanning. These scripts are versioned, testable, and reusable across multiple workflows.

> **For Support & Sales:** See [SECURITY.md](SECURITY.md) for a guide on understanding vulnerability reports, terminology definitions, and how to interpret scan results.

## Overview

The scripts handle various aspects of Docker image vulnerability scanning:

- **Extraction**: Extracting nested JARs and Python packages from Docker images
- **Analysis**: Analyzing and combining scan results from multiple scanners
- **Reporting**: Generating detailed vulnerability reports
- **Utilities**: Common operations like file checking and result conversion

## Scripts

### Core Scanning Scripts

#### `extract-nested-deps.sh`

Extracts nested JARs and Python packages from Liquibase Docker images for deep vulnerability scanning.

**Usage:**
```bash
./extract-nested-deps.sh <image_ref>
```

**Arguments:**
- `image_ref`: Docker image reference (e.g., `liquibase/liquibase:latest`)

**Environment Variables:**
- `EXTRACT_DIR`: Base directory for extraction (default: `/tmp/extracted-deps`)

**Outputs:**
- Extracted JAR files in `${EXTRACT_DIR}/internal-jars/{lib,extensions}`
- Nested JARs from archives in `${EXTRACT_DIR}/dist/`
- Python packages in `${EXTRACT_DIR}/python-packages`
- JAR mapping file in `${EXTRACT_DIR}/jar-mapping.txt`

**Example:**
```bash
# Extract from local image
./extract-nested-deps.sh liquibase/liquibase:latest

# Extract from image with SHA
./extract-nested-deps.sh liquibase/liquibase:abc123
```

---

#### `analyze-scan-results.sh`

Analyzes and combines vulnerability scan results from Trivy and Grype scanners.

**Usage:**
```bash
IMAGE_NAME="liquibase/liquibase" IMAGE_SUFFIX="-alpine" ./analyze-scan-results.sh
```

**Environment Variables:**
- `EXTRACT_DIR`: Directory containing `jar-mapping.txt` (default: `/tmp/extracted-deps`)
- `IMAGE_NAME`: Name of the image being scanned
- `IMAGE_SUFFIX`: Suffix for the image variant (e.g., `-alpine`)
- `GITHUB_STEP_SUMMARY`: GitHub Actions summary file path (optional)
- `GITHUB_SHA`: Git commit SHA (optional)

**Expected Input Files:**
- `trivy-surface.json`: Trivy surface scan results
- `trivy-deep.json`: Trivy deep scan results
- `grype-results.sarif`: Grype SARIF results

**Outputs:**
- `vulnerability-report-enhanced.md`: Detailed vulnerability report
- `scan-summary.txt`: Summary of scan results
- Exit code 1 if vulnerabilities found, 0 otherwise
- GitHub Actions step summary (if `GITHUB_STEP_SUMMARY` is set)

---

#### `convert-scan-results.sh`

Converts Trivy JSON scan results to SARIF format and counts vulnerabilities.

**Usage:**
```bash
./convert-scan-results.sh
```

**Requirements:**
- Trivy CLI must be installed

**Expected Input Files:**
- `trivy-surface.json`: Trivy surface scan results (optional)
- `trivy-deep.json`: Trivy deep scan results (optional)
- `grype-results.json`: Grype JSON results (optional)

**Outputs:**
- `trivy-surface.sarif`: Converted SARIF format
- `trivy-deep.sarif`: Converted SARIF format
- Environment variables (if `GITHUB_ENV` is set): `surface_vulns`, `deep_vulns`, `grype_vulns`, `total_vulns`

**Example:**
```bash
# Convert scan results after running Trivy
trivy image --format json --output trivy-surface.json liquibase/liquibase:latest
./convert-scan-results.sh
```

---

### Reporting Scripts

#### `create-enhanced-report.sh`

Creates an enhanced vulnerability report with parent JAR mapping for nested dependencies.

**Usage:**
```bash
./create-enhanced-report.sh <image> <tag>
```

**Arguments:**
- `image`: Docker image name (e.g., `liquibase/liquibase`)
- `tag`: Image tag (e.g., `4.28.0`)

**Environment Variables:**
- `EXTRACT_DIR`: Directory containing `jar-mapping.txt` (default: `/tmp/extracted-deps`)
- `surface_vulns`: Number of surface vulnerabilities
- `deep_vulns`: Number of deep vulnerabilities
- `grype_vulns`: Number of Grype vulnerabilities
- `total_vulns`: Total vulnerabilities

**Expected Input Files:**
- `trivy-deep.json`: Trivy deep scan results
- `${EXTRACT_DIR}/jar-mapping.txt`: Parent JAR mapping file

**Outputs:**
- `vulnerability-report-enhanced.md`: Detailed report with JAR relationships

---

#### `append-github-summary.sh`

Appends detailed vulnerability information to GitHub Actions step summary.

**Usage:**
```bash
./append-github-summary.sh <image> <tag>
```

**Arguments:**
- `image`: Docker image name (e.g., `liquibase/liquibase`)
- `tag`: Image tag (e.g., `4.28.0`)

**Environment Variables:**
- `EXTRACT_DIR`: Directory containing `jar-mapping.txt` (default: `/tmp/extracted-deps`)
- `surface_vulns`: Number of surface vulnerabilities
- `deep_vulns`: Number of deep vulnerabilities
- `grype_vulns`: Number of Grype vulnerabilities
- `total_vulns`: Total vulnerabilities
- `GITHUB_STEP_SUMMARY`: GitHub Actions summary file path (required)

**Expected Input Files:**
- `trivy-surface.json`: Trivy surface scan results
- `trivy-deep.json`: Trivy deep scan results
- `grype-results.json`: Grype JSON results

**Note:** This script only runs in GitHub Actions environment.

---

### Utility Scripts

#### `generate-dockerhub-matrix.sh`

Generates a JSON matrix of Docker images and tags to scan from Docker Hub.

**Usage:**
```bash
./generate-dockerhub-matrix.sh [max_tags]
```

**Arguments:**
- `max_tags`: Maximum number of tags to scan per image (default: 10)

**Environment Variables:**
- `MAX_TAGS`: Maximum tags per image (overrides argument)
- `GITHUB_OUTPUT`: GitHub Actions output file path (optional)

**Outputs:**
- JSON matrix written to stdout and `$GITHUB_OUTPUT` if available
- Format: `{"include":[{"image":"...","tag":"..."}]}`

**Example:**
```bash
# Generate matrix for 5 most recent tags
./generate-dockerhub-matrix.sh 5

# Use in GitHub Actions
MAX_TAGS=10 ./generate-dockerhub-matrix.sh
```

---

#### `save-grype-results.sh`

Locates and saves Grype scan results to a consistent filename.

**Usage:**
```bash
./save-grype-results.sh [output_filename]
```

**Arguments:**
- `output_filename`: Desired output filename (default: `grype-results.sarif` or `grype-results.json`)

**Environment Variables:**
- `GRYPE_OUTPUT_FORMAT`: Output format - `sarif` or `json` (default: `sarif`)

**Outputs:**
- Grype results saved to specified filename
- Exit code 0 on success, 1 if no results found

**Example:**
```bash
# Save SARIF results
GRYPE_OUTPUT_FORMAT=sarif ./save-grype-results.sh

# Save JSON results with custom name
GRYPE_OUTPUT_FORMAT=json ./save-grype-results.sh my-grype-results.json
```

---

#### `check-file-exists.sh`

Checks if a file exists and optionally sets GitHub Actions output.

**Usage:**
```bash
./check-file-exists.sh <filename> [output_name]
```

**Arguments:**
- `filename`: Path to the file to check
- `output_name`: Name for GitHub Actions output variable (default: `exists`)

**Environment Variables:**
- `GITHUB_OUTPUT`: GitHub Actions output file path (optional)

**Outputs:**
- GitHub Actions output: `<output_name>=true` or `false`
- Exit code 0 (always succeeds)

**Example:**
```bash
# Check if SARIF file exists
./check-file-exists.sh trivy-deep.sarif

# In GitHub Actions workflow
./check-file-exists.sh grype-results.sarif grype_exists
# Sets output: grype_exists=true or grype_exists=false
```

---

## Workflow Integration

### Example: Using in trivy.yml workflow

```yaml
- name: Extract nested JARs and Python packages
  run: |
    scripts/extract-nested-deps.sh ${{ matrix.image.name }}${{ matrix.image.suffix }}:${{ github.sha }}

- name: Analyze scan results
  if: always()
  env:
    IMAGE_NAME: ${{ matrix.image.name }}
    IMAGE_SUFFIX: ${{ matrix.image.suffix }}
  run: |
    scripts/analyze-scan-results.sh
```

### Example: Using in trivy-scan-published-images.yml workflow

```yaml
- name: Generate scan matrix
  id: set-matrix
  run: |
    MATRIX=$(scripts/generate-dockerhub-matrix.sh 10)
    echo "matrix=$MATRIX" >> $GITHUB_OUTPUT

- name: Extract nested dependencies
  run: |
    scripts/extract-nested-deps.sh ${{ matrix.image }}:${{ matrix.tag }}

- name: Convert and analyze results
  run: |
    scripts/convert-scan-results.sh

- name: Create enhanced report
  env:
    surface_vulns: ${{ env.surface_vulns }}
    deep_vulns: ${{ env.deep_vulns }}
    grype_vulns: ${{ env.grype_vulns }}
    total_vulns: ${{ env.total_vulns }}
  run: |
    scripts/create-enhanced-report.sh ${{ matrix.image }} ${{ matrix.tag }}

- name: Append to GitHub summary
  run: |
    scripts/append-github-summary.sh ${{ matrix.image }} ${{ matrix.tag }}
```

## Testing Scripts Locally

All scripts can be tested locally outside of GitHub Actions:

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Test extraction
docker build -t test-image:latest .
scripts/extract-nested-deps.sh test-image:latest

# Test report generation (create dummy scan results first)
echo '{"Results":[]}' > trivy-surface.json
echo '{"Results":[]}' > trivy-deep.json
IMAGE_NAME="test-image" scripts/analyze-scan-results.sh

# Test matrix generation
scripts/generate-dockerhub-matrix.sh 5
```

## Dependencies

### Required Tools

- **bash**: Shell interpreter (version 4.0+)
- **jq**: JSON processor
- **docker**: For image extraction operations
- **curl**: For Docker Hub API access (matrix generation)
- **trivy**: For SARIF conversion (convert-scan-results.sh only)

### Optional Tools

- **unzip**: For JAR extraction (usually pre-installed)
- **tar**: For archive extraction (usually pre-installed)

## Error Handling

All scripts use appropriate error handling:

- Scripts that should fail on errors use `set -e`
- Analysis scripts use `set +e` to collect all results before exiting
- Utility scripts always exit with code 0 to avoid breaking workflows
- Missing files and tools are reported with clear error messages

## File Permissions

After cloning the repository, make all scripts executable:

```bash
chmod +x scripts/*.sh
```

Or use git to track executable permissions:

```bash
git update-index --chmod=+x scripts/*.sh
```

## Contributing

When adding or modifying scripts:

1. **Add header comments**: Include purpose, usage, arguments, and outputs
2. **Use environment variables**: Make scripts configurable via environment
3. **Handle errors gracefully**: Don't fail workflows unnecessarily
4. **Test locally**: Verify scripts work outside GitHub Actions
5. **Update this README**: Document new scripts and changes
6. **Follow naming conventions**: Use descriptive, kebab-case names

## Migration Notes

These scripts were extracted from inline shell code in:
- `.github/workflows/trivy.yml`
- `.github/workflows/trivy-scan-published-images.yml`

Benefits of extraction:
- ✅ Version control for scanning logic
- ✅ Easier to test and debug
- ✅ Reusable across workflows
- ✅ Smaller, more readable workflow files
- ✅ Consistent behavior between workflows