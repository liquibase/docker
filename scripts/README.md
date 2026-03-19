# Vulnerability Scanning Scripts

This directory contains shell scripts used by GitHub Actions workflows for vulnerability scanning.

> **For Support & Sales:** See [SECURITY.md](../SECURITY.md) for a guide on understanding vulnerability reports, terminology definitions, and how to interpret scan results.

## Scripts

### `generate-dockerhub-matrix.sh`

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

## Dependencies

- **bash**: Shell interpreter (version 4.0+)
- **jq**: JSON processor
- **curl**: For Docker Hub API access

## File Permissions

After cloning the repository, make all scripts executable:

```bash
chmod +x scripts/*.sh
```
