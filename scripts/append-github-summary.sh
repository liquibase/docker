#!/usr/bin/env bash
#
# append-github-summary.sh
#
# Appends detailed vulnerability information to GitHub Actions step summary.
# This script generates formatted markdown tables for GitHub Actions UI.
#
# Usage:
#   append-github-summary.sh <image> <tag> [published]
#
# Arguments:
#   image: Docker image name (e.g., liquibase/liquibase)
#   tag: Image tag (e.g., 4.28.0)
#   published: ISO 8601 timestamp of when the image tag was last updated (optional)
#
# Environment Variables:
#   EXTRACT_DIR: Directory containing jar-mapping.txt (default: /tmp/extracted-deps)
#   surface_vulns: Number of surface vulnerabilities
#   deep_vulns: Number of deep vulnerabilities
#   grype_vulns: Number of Grype vulnerabilities
#   total_vulns: Total vulnerabilities
#   GITHUB_STEP_SUMMARY: GitHub Actions summary file path
#
# Expected Input Files:
#   - trivy-surface.json: Trivy surface scan results
#   - trivy-deep.json: Trivy deep scan results
#   - grype-results.json: Grype JSON results
#
# Outputs:
#   - Appends to $GITHUB_STEP_SUMMARY

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

# Ensure we're running in GitHub Actions
if [ -z "${GITHUB_STEP_SUMMARY:-}" ]; then
  echo "⚠️  Not running in GitHub Actions, skipping summary generation"
  exit 0
fi

echo "📊 Appending vulnerability details to GitHub Actions summary..."

# Create summary header
{
  echo "## 🛡️ Vulnerability Scan Results for \`${IMAGE}:${TAG}\`"
  echo ""
  echo "**Image Last Updated**: ${PUBLISHED_DATE}"
  echo ""
  echo "**Total HIGH/CRITICAL Vulnerabilities: ${total_vulns}**"
  echo ""
  echo "| Scanner | Vulnerabilities | Status |"
  echo "|---------|-----------------|--------|"
  echo "| 🔍 OS & Application Libraries | ${surface_vulns} | $([ "$surface_vulns" -eq 0 ] && echo '✅' || echo '⚠️') |"
  echo "| 🔎 Nested JAR Dependencies | ${deep_vulns} | $([ "$deep_vulns" -eq 0 ] && echo '✅' || echo '⚠️') |"
  echo "| 📋 Grype (SBOM-based) | ${grype_vulns} | $([ "$grype_vulns" -eq 0 ] && echo '✅' || echo '⚠️') |"
  echo ""
} >> "$GITHUB_STEP_SUMMARY"

# Add scan targets section (collapsible)
{
  echo "<details>"
  echo "<summary>📁 Scan Targets (click to expand)</summary>"
  echo ""
  echo "**OS & Application Libraries:**"
  if [ -f trivy-surface.json ]; then
    jq -r '[.Results[].Target] | unique | .[]' trivy-surface.json 2>/dev/null | sed 's/^/- /' || echo "- (no targets found)"
  else
    echo "- (scan results not available)"
  fi
  echo ""
  echo "**Nested JAR Dependencies:**"
  if [ -f "${EXTRACT_DIR}/scanned-jars.txt" ]; then
    jar_count=$(wc -l < "${EXTRACT_DIR}/scanned-jars.txt" | tr -d ' ')
    echo "*(${jar_count} JAR files scanned)*"
    head -20 "${EXTRACT_DIR}/scanned-jars.txt" | sed 's/^/- /'
    if [ "$jar_count" -gt 20 ]; then
      echo "- ... and $((jar_count - 20)) more"
      echo ""
      echo "📎 *Full report available in workflow artifacts*"
    fi
  elif [ -f trivy-deep.json ]; then
    # Fallback to Trivy JSON if manifest not available
    target_count=$(jq -r '[.Results[].Target] | unique | length' trivy-deep.json 2>/dev/null || echo 0)
    echo "*(${target_count} files scanned)*"
    jq -r '[.Results[].Target | split("/")[-1]] | unique | sort | .[]' trivy-deep.json 2>/dev/null | head -20 | sed 's/^/- /' || echo "- (no targets found)"
    if [ "$target_count" -gt 20 ]; then
      echo "- ... and $((target_count - 20)) more"
      echo ""
      echo "📎 *Full report available in workflow artifacts*"
    fi
  else
    echo "- (scan results not available)"
  fi
  echo ""
  echo "</details>"
  echo ""
} >> "$GITHUB_STEP_SUMMARY"

# Add detailed vulnerability tables
if [ "$surface_vulns" -gt 0 ] && [ -f trivy-surface.json ]; then
  {
    echo "### 🔍 OS & Application Library Vulnerabilities"
    echo ""
    echo "| Package | NVD | GitHub Advisories | CVE Published | Trivy Severity | Trivy Vendor Data | Installed | Fixed | Fix? |"
    echo "|---------|-----|-------------------|---------------|----------------|-----------------|-----------|-------|------|"
  } >> "$GITHUB_STEP_SUMMARY"

  jq -r '.Results[]?.Vulnerabilities[]? | select(.Severity == "HIGH" or .Severity == "CRITICAL") |
    .VulnerabilityID as $cve |
    '"${JQ_VENDOR_FILTER}"' |
    "| \(.PkgName) | [\($cve)](https://nvd.nist.gov/vuln/detail/\($cve)) | [Search](https://github.com/advisories?query=\($cve)) | \((.PublishedDate // "-") | split("T")[0]) | \(.Severity) | \(if $vendor[2] != "" then "[\($vendor[0]):\($vendor[1])](\($vendor[2]))" else "\($vendor[0]):\($vendor[1])" end) | \(.InstalledVersion) | \(.FixedVersion // "-") | \(if (.FixedVersion // "") != "" then "✅" else "❌" end) |"' \
    trivy-surface.json 2>/dev/null | head -20 >> "$GITHUB_STEP_SUMMARY" || echo "| Error parsing results | - | - | - | - | - | - | - | - |" >> "$GITHUB_STEP_SUMMARY"

  echo "" >> "$GITHUB_STEP_SUMMARY"
fi

if [ "$deep_vulns" -gt 0 ] && [ -f trivy-deep.json ]; then
  {
    echo "### 🔎 Nested JAR Dependency Vulnerabilities"
    echo ""
    echo "| Parent JAR | Package | NVD | GitHub Advisories | CVE Published | Trivy Severity | Trivy Vendor Data | Installed | Fixed | Fix? |"
    echo "|------------|---------|-----|-------------------|---------------|----------------|-----------------|-----------|-------|------|"
  } >> "$GITHUB_STEP_SUMMARY"

  # Process each vulnerability and look up parent JAR from mapping file
  # First, collect all rows into a temp file, then deduplicate
  temp_table="/tmp/vuln-table-$$.txt"
  > "$temp_table"  # Clear temp file

  jq -r '.Results[]? | .Target as $target | .Vulnerabilities[]? |
    select(.Severity == "HIGH" or .Severity == "CRITICAL") |
    .VulnerabilityID as $cve |
    '"${JQ_VENDOR_FILTER}"' |
    "\($target)|\(.PkgPath // "")|\(.PkgName)|\($cve)|\((.PublishedDate // "-") | split("T")[0])|\(.Severity)|\($vendor[0]):\($vendor[1])|\($vendor[2])|\(.InstalledVersion)|\(.FixedVersion // "-")|\(if (.FixedVersion // "") != "" then "Y" else "N" end)"' \
    trivy-deep.json 2>/dev/null | while IFS='|' read -r target pkgpath pkg vuln cve_date severity vendor_sev vendor_url installed fixed has_fix; do

    # Use PkgPath if available (contains JAR file path), otherwise use Target
    jar_path="${pkgpath:-$target}"

    # Extract JAR filename from path (handle both file paths and directory paths)
    if [[ "$jar_path" == *.jar ]]; then
      jar_file=$(basename "$jar_path" 2>/dev/null || echo "$jar_path")
    else
      # Path might be a directory containing a JAR, extract JAR name from path
      jar_file=$(echo "$jar_path" | grep -oE '[^/]+\.jar' | tail -1)
      if [ -z "$jar_file" ]; then
        jar_file=$(basename "$jar_path" 2>/dev/null || echo "$jar_path")
      fi
    fi

    # Look up parent JAR from mapping file
    parent_jar="(internal)"
    if [ -f "${EXTRACT_DIR}/jar-mapping.txt" ] && [ -n "$jar_file" ]; then
      # Try exact match first
      parent_match=$(grep -F "$jar_file" "${EXTRACT_DIR}/jar-mapping.txt" 2>/dev/null | cut -d'|' -f1 | tr -d ' ' | head -1)
      if [ -n "$parent_match" ]; then
        parent_jar="$parent_match"
      fi
    fi

    # Format vendor severity with link if URL available
    if [ -n "$vendor_url" ]; then
      vendor_display="[$vendor_sev]($vendor_url)"
    else
      vendor_display="$vendor_sev"
    fi
    # Format fix indicator
    fix_indicator=$([ "$has_fix" = "Y" ] && echo "✅" || echo "❌")
    echo "| $parent_jar | $pkg | [$vuln](https://nvd.nist.gov/vuln/detail/$vuln) | [Search](https://github.com/advisories?query=$vuln) | $cve_date | $severity | $vendor_display | $installed | $fixed | $fix_indicator |" >> "$temp_table"
  done

  # Deduplicate and add to summary (limit to 40 entries)
  sort -u "$temp_table" | head -40 >> "$GITHUB_STEP_SUMMARY"
  rm -f "$temp_table"

  echo "" >> "$GITHUB_STEP_SUMMARY"
fi

if [ "$grype_vulns" -gt 0 ] && [ -f grype-results.json ]; then
  {
    echo "### 📋 Grype SBOM Scan Details"
    echo ""
    echo "| Package | NVD | GitHub Advisories | Grype Severity | Installed | Fixed | Fix? |"
    echo "|---------|-----|-------------------|----------------|-----------|-------|------|"
  } >> "$GITHUB_STEP_SUMMARY"

  # Note: Grype JSON doesn't include CVE publish dates or vendor severity in the standard output
  # Use suggestedVersion from matchDetails when available (filters to relevant version for installed package)
  jq -r '.matches[]? | select(.vulnerability.severity == "High" or .vulnerability.severity == "Critical") |
    (.matchDetails[0].fix.suggestedVersion // .vulnerability.fix.versions[0] // "-") as $fixVersion |
    "| \(.artifact.name) | [\(.vulnerability.id)](https://nvd.nist.gov/vuln/detail/\(.vulnerability.id)) | [Search](https://github.com/advisories?query=\(.vulnerability.id)) | \(.vulnerability.severity) | \(.artifact.version) | \($fixVersion) | \(if $fixVersion != "-" then "✅" else "❌" end) |"' \
    grype-results.json 2>/dev/null | head -20 >> "$GITHUB_STEP_SUMMARY" || echo "| Error parsing results | - | - | - | - | - | - |" >> "$GITHUB_STEP_SUMMARY"

  echo "" >> "$GITHUB_STEP_SUMMARY"
fi

echo "✅ GitHub Actions summary updated"
