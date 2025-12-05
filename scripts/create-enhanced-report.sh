#!/usr/bin/env bash
#
# create-enhanced-report.sh
#
# Creates an enhanced vulnerability report with parent JAR mapping for nested dependencies.
# This script is specifically designed for published images scanning workflow.
#
# Usage:
#   create-enhanced-report.sh <image> <tag> [published]
#
# Arguments:
#   image: Docker image name (e.g., liquibase/liquibase)
#   tag: Image tag (e.g., 4.28.0)
#   published: ISO 8601 timestamp of when the image tag was last updated (optional)
#
# Environment Variables:
#   EXTRACT_DIR: Directory containing jar-mapping.txt (default: /tmp/extracted-deps)
#   surface_vulns: Number of surface vulnerabilities (from previous step)
#   deep_vulns: Number of deep vulnerabilities (from previous step)
#   grype_vulns: Number of Grype vulnerabilities (from previous step)
#   total_vulns: Total vulnerabilities (from previous step)
#
# Expected Input Files:
#   - trivy-deep.json: Trivy deep scan results
#   - ${EXTRACT_DIR}/jar-mapping.txt: Parent JAR mapping file
#
# Outputs:
#   - vulnerability-report-enhanced.md: Detailed report with JAR relationships

set -e

# Source shared jq filters
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/vuln-filters.sh
source "${SCRIPT_DIR}/lib/vuln-filters.sh"

# Arguments
IMAGE="${1:?Error: Image name required}"
TAG="${2:?Error: Tag required}"
PUBLISHED="${3:-}"

# Format the published date for display (extract just the date part YYYY-MM-DD)
if [ -n "$PUBLISHED" ] && [ "$PUBLISHED" != "unknown" ]; then
  PUBLISHED_DATE="${PUBLISHED%%T*}"
else
  PUBLISHED_DATE="unknown"
fi

# Environment variables
EXTRACT_DIR="${EXTRACT_DIR:-/tmp/extracted-deps}"
surface_vulns="${surface_vulns:-0}"
deep_vulns="${deep_vulns:-0}"
grype_vulns="${grype_vulns:-0}"
total_vulns="${total_vulns:-0}"

report_file="vulnerability-report-enhanced.md"

echo "📝 Creating enhanced vulnerability report for ${IMAGE}:${TAG}..."

# Create report header
{
  echo "# Enhanced Vulnerability Report"
  echo ""
  echo "**Image**: \`${IMAGE}:${TAG}\`"
  echo "**Image Last Updated**: ${PUBLISHED_DATE}"
  echo "**Scan Date**: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  echo ""
  echo "## Summary"
  echo ""
  echo "| Scanner | HIGH/CRITICAL Vulnerabilities |"
  echo "|---------|-------------------------------|"
  echo "| OS & Application Libraries | ${surface_vulns} |"
  echo "| Nested JAR Dependencies | ${deep_vulns} |"
  echo "| Grype (SBOM-based) | ${grype_vulns} |"
  echo "| **Total** | **${total_vulns}** |"
  echo ""
  if [ "$total_vulns" -eq 0 ]; then
    echo "**No HIGH/CRITICAL vulnerabilities found.**"
    echo ""
  fi
} > "$report_file"

# Add scan targets section
{
  echo "## Scan Targets"
  echo ""
  echo "### OS & Application Libraries"
  if [ -f trivy-surface.json ]; then
    jq -r '[.Results[].Target] | unique | .[]' trivy-surface.json 2>/dev/null | sed 's/^/- /' || echo "- (no targets found)"
  else
    echo "- (scan results not available)"
  fi
  echo ""
  echo "### Nested JAR Dependencies"
  if [ -f "${EXTRACT_DIR}/scanned-jars.txt" ]; then
    jar_count=$(wc -l < "${EXTRACT_DIR}/scanned-jars.txt" | tr -d ' ')
    echo "*(${jar_count} JAR files scanned)*"
    echo ""
    cat "${EXTRACT_DIR}/scanned-jars.txt" | sed 's/^/- /'
  elif [ -f trivy-deep.json ]; then
    # Fallback to Trivy JSON if manifest not available
    target_count=$(jq -r '[.Results[].Target] | unique | length' trivy-deep.json 2>/dev/null || echo 0)
    echo "*(${target_count} files scanned)*"
    echo ""
    jq -r '[.Results[].Target | split("/")[-1]] | unique | sort | .[]' trivy-deep.json 2>/dev/null | sed 's/^/- /' || echo "- (no targets found)"
  else
    echo "- (scan results not available)"
  fi
  echo ""
} >> "$report_file"

# Add OS & Application Library vulnerabilities (only if found)
if [ "$surface_vulns" -gt 0 ] && [ -f trivy-surface.json ]; then
  {
    echo "## OS & Application Library Vulnerabilities"
    echo ""
    echo "| Package | NVD | GitHub Advisories | CVE Published | Trivy Severity | Trivy Vendor Data | Installed | Fixed | Fix? |"
    echo "|---------|-----|-------------------|---------------|----------------|-----------------|-----------|-------|------|"
  } >> "$report_file"

  jq -r '.Results[]?.Vulnerabilities[]? | select(.Severity == "HIGH" or .Severity == "CRITICAL") |
    .VulnerabilityID as $cve |
    '"${JQ_VENDOR_FILTER}"' |
    "\(.PkgName)|\($cve)|\((.PublishedDate // "-") | split("T")[0])|\(.Severity)|\($vendor[0]):\($vendor[1])|\($vendor[2])|\(.InstalledVersion)|\(.FixedVersion // "-")|\(if .FixedVersion then "Y" else "N" end)"' \
    trivy-surface.json 2>/dev/null | while IFS='|' read -r pkg vuln cve_date severity vendor_sev vendor_url installed fixed has_fix; do
    # Format vendor severity with link if URL available
    if [ -n "$vendor_url" ]; then
      vendor_display="[$vendor_sev]($vendor_url)"
    else
      vendor_display="$vendor_sev"
    fi
    # Format fix indicator
    fix_indicator=$([ "$has_fix" = "Y" ] && echo "✅" || echo "❌")
    echo "| $pkg | [$vuln](https://nvd.nist.gov/vuln/detail/$vuln) | [Search](https://github.com/advisories?query=$vuln) | $cve_date | $severity | $vendor_display | $installed | $fixed | $fix_indicator |" >> "$report_file"
  done

  echo "" >> "$report_file"
fi

# Add parent JAR mapping section (only if vulnerabilities found)
if [ -f "${EXTRACT_DIR}/jar-mapping.txt" ] && [ "$deep_vulns" -gt 0 ]; then
  {
    echo "## Parent JAR Relationships"
    echo ""
    echo "The following shows which Liquibase JARs contain vulnerable nested dependencies:"
    echo ""
    echo "\`\`\`"
    cat "${EXTRACT_DIR}/jar-mapping.txt" | sort | uniq
    echo "\`\`\`"
    echo ""
  } >> "$report_file"
fi

# Add detailed vulnerability table with parent JAR context (only if vulnerabilities found)
if [ -f trivy-deep.json ] && [ "$deep_vulns" -gt 0 ]; then
  {
    echo "## Detailed Vulnerability Analysis"
    echo ""
    echo "### Nested JAR Vulnerabilities"
    echo ""
    echo "| Parent JAR | Nested JAR | NVD | GitHub Advisories | CVE Published | Trivy Severity | Trivy Vendor Data | Installed | Fixed | Fix? |"
    echo "|------------|------------|-----|-------------------|---------------|----------------|-----------------|-----------|-------|------|"
  } >> "$report_file"

  # Process each vulnerability and match with parent JAR
  jq -r '.Results[]? | .Target as $target | .Vulnerabilities[]? |
    select(.Severity == "HIGH" or .Severity == "CRITICAL") |
    .VulnerabilityID as $cve |
    '"${JQ_VENDOR_FILTER}"' |
    "\($target)|\(.PkgName)|\($cve)|\((.PublishedDate // "-") | split("T")[0])|\(.Severity)|\($vendor[0]):\($vendor[1])|\($vendor[2])|\(.InstalledVersion)|\(.FixedVersion // "-")|\(if .FixedVersion then "Y" else "N" end)"' \
    trivy-deep.json 2>/dev/null | while IFS='|' read -r target pkg vuln cve_date severity vendor_sev vendor_url installed fixed has_fix; do

    # Extract JAR name from target path
    jar_file=$(basename "$target" 2>/dev/null || echo "$target")

    # Find parent JAR from mapping file
    if [ -f "${EXTRACT_DIR}/jar-mapping.txt" ]; then
      parent_jar=$(grep "$jar_file" "${EXTRACT_DIR}/jar-mapping.txt" | cut -d'|' -f1 | tr -d ' ' | head -1)
      if [ -z "$parent_jar" ]; then
        parent_jar="(internal)"
      fi
    else
      parent_jar="(unknown)"
    fi

    # Format vendor severity with link if URL available
    if [ -n "$vendor_url" ]; then
      vendor_display="[$vendor_sev]($vendor_url)"
    else
      vendor_display="$vendor_sev"
    fi
    # Format fix indicator
    fix_indicator=$([ "$has_fix" = "Y" ] && echo "✅" || echo "❌")
    echo "| $parent_jar | $jar_file | [$vuln](https://nvd.nist.gov/vuln/detail/$vuln) | [Search](https://github.com/advisories?query=$vuln) | $cve_date | $severity | $vendor_display | $installed | $fixed | $fix_indicator |" >> "$report_file"
  done

  echo "" >> "$report_file"
fi

# Add Python vulnerabilities
if [ -f trivy-deep.json ]; then
  python_vulns=$(jq '[.Results[]? | select(.Type == "python-pkg") | .Vulnerabilities[]? | select(.Severity == "HIGH" or .Severity == "CRITICAL")] | length' trivy-deep.json 2>/dev/null || echo 0)

  if [ "$python_vulns" -gt 0 ]; then
    {
      echo "### Python Package Vulnerabilities"
      echo ""
      echo "These are found in extension JARs (GraalVM Python VFS)"
      echo ""
      echo "| Package | NVD | GitHub Advisories | CVE Published | Trivy Severity | Trivy Vendor Data | Installed | Fixed | Fix? |"
      echo "|---------|-----|-------------------|---------------|----------------|-----------------|-----------|-------|------|"
    } >> "$report_file"

    jq -r '.Results[]? | select(.Type == "python-pkg") | .Vulnerabilities[]? |
      select(.Severity == "HIGH" or .Severity == "CRITICAL") |
      .VulnerabilityID as $cve |
      '"${JQ_VENDOR_FILTER}"' |
      "\(.PkgName)|\($cve)|\((.PublishedDate // "-") | split("T")[0])|\(.Severity)|\($vendor[0]):\($vendor[1])|\($vendor[2])|\(.InstalledVersion)|\(.FixedVersion // "-")|\(if .FixedVersion then "Y" else "N" end)"' \
      trivy-deep.json 2>/dev/null | while IFS='|' read -r pkg vuln cve_date severity vendor_sev vendor_url installed fixed has_fix; do
      # Format vendor severity with link if URL available
      if [ -n "$vendor_url" ]; then
        vendor_display="[$vendor_sev]($vendor_url)"
      else
        vendor_display="$vendor_sev"
      fi
      # Format fix indicator
      fix_indicator=$([ "$has_fix" = "Y" ] && echo "✅" || echo "❌")
      echo "| $pkg | [$vuln](https://nvd.nist.gov/vuln/detail/$vuln) | [Search](https://github.com/advisories?query=$vuln) | $cve_date | $severity | $vendor_display | $installed | $fixed | $fix_indicator |" >> "$report_file"
    done

    echo "" >> "$report_file"
  fi
fi

# Add Grype SBOM scan vulnerabilities (only if found)
if [ "$grype_vulns" -gt 0 ] && [ -f grype-results.json ]; then
  {
    echo "## Grype SBOM Scan Details"
    echo ""
    echo "| Package | NVD | GitHub Advisories | Grype Severity | Installed | Fixed | Fix? |"
    echo "|---------|-----|-------------------|----------------|-----------|-------|------|"
  } >> "$report_file"

  # Use suggestedVersion from matchDetails when available (filters to relevant version for installed package)
  jq -r '.matches[]? | select(.vulnerability.severity == "High" or .vulnerability.severity == "Critical") |
    (.matchDetails[0].fix.suggestedVersion // .vulnerability.fix.versions[0] // "-") as $fixVersion |
    "\(.artifact.name)|\(.vulnerability.id)|\(.vulnerability.severity)|\(.artifact.version)|\($fixVersion)|\(if $fixVersion != "-" then "Y" else "N" end)"' \
    grype-results.json 2>/dev/null | while IFS='|' read -r pkg vuln severity installed fixed has_fix; do
    # Format fix indicator
    fix_indicator=$([ "$has_fix" = "Y" ] && echo "✅" || echo "❌")
    echo "| $pkg | [$vuln](https://nvd.nist.gov/vuln/detail/$vuln) | [Search](https://github.com/advisories?query=$vuln) | $severity | $installed | $fixed | $fix_indicator |" >> "$report_file"
  done

  echo "" >> "$report_file"
fi

echo "✓ Enhanced vulnerability report created: $report_file"
