# Vulnerability Scanning Scripts

This directory contains shell scripts used by GitHub Actions workflows for vulnerability scanning of published Docker images.

> **For Support & Sales:** See [SECURITY.md](../SECURITY.md) for a guide on understanding vulnerability reports, terminology definitions, and how to interpret scan results.

## Scripts

### `generate-dockerhub-matrix.sh`

Generates a JSON matrix of Docker images and tags to scan from Docker Hub. Used by the `trivy-scan-published-images.yml` workflow to determine which published tags to scan.

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
- Format: `{"include":[{"image":"...","tag":"...","published":"..."}]}`

**Example:**
```bash
# Generate matrix for 5 most recent tags
./generate-dockerhub-matrix.sh 5

# Use in GitHub Actions
MAX_TAGS=10 ./generate-dockerhub-matrix.sh
```

**How it works:**
1. Queries Docker Hub API for active tags of `liquibase/liquibase` and `liquibase/liquibase-secure`
2. Filters to semantic version tags only (e.g., `5.0.1`, `4.28`)
3. Removes redundant minor version tags when the full version exists (e.g., skips `4.28` if `4.28.0` exists)
4. Returns the most recent N tags per image as a GitHub Actions matrix

## Dependencies

- **bash**: Shell interpreter (version 4.0+)
- **jq**: JSON processor
- **curl**: For Docker Hub API access

## Related Documentation

- [SECURITY.md](../SECURITY.md) - Understanding vulnerability scan reports
- [Trivy Documentation](https://trivy.dev/) - Official Trivy scanner documentation
- [Grype Documentation](https://github.com/anchore/grype) - Official Grype scanner documentation
