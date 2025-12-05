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

# Add parent JAR mapping section
if [ -f "${EXTRACT_DIR}/jar-mapping.txt" ]; then
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

# Add detailed vulnerability table with parent JAR context
if [ -f trivy-deep.json ]; then
  {
    echo "## Detailed Vulnerability Analysis"
    echo ""
    echo "### Nested JAR Vulnerabilities"
    echo ""
    echo "| Parent JAR | Nested JAR | NVD | GitHub Advisories | CVE Published | Trivy Severity | Vendor Severity | Installed | Fixed | Fix? |"
    echo "|------------|------------|-----|-------------------|---------------|----------------|-----------------|-----------|-------|------|"
  } >> "$report_file"

  # Process each vulnerability and match with parent JAR
  jq -r '.Results[]? | .Target as $target | .Vulnerabilities[]? |
    select(.Severity == "HIGH" or .Severity == "CRITICAL") |
    .VulnerabilityID as $cve |
    (if .VendorSeverity.nvd then ["nvd", (.VendorSeverity.nvd | if . == 1 then "L" elif . == 2 then "M" elif . == 3 then "H" elif . == 4 then "C" else "-" end), "https://nvd.nist.gov/vuln/detail/\($cve)"] elif .VendorSeverity.ghsa then ["ghsa", (.VendorSeverity.ghsa | if . == 1 then "L" elif . == 2 then "M" elif . == 3 then "H" elif . == 4 then "C" else "-" end), "https://github.com/advisories?query=\($cve)"] elif .VendorSeverity.redhat then ["rh", (.VendorSeverity.redhat | if . == 1 then "L" elif . == 2 then "M" elif . == 3 then "H" elif . == 4 then "C" else "-" end), "https://access.redhat.com/security/cve/\($cve)"] elif .VendorSeverity.amazon then ["amz", (.VendorSeverity.amazon | if . == 1 then "L" elif . == 2 then "M" elif . == 3 then "H" elif . == 4 then "C" else "-" end), "https://alas.aws.amazon.com/cve/html/\($cve).html"] elif .VendorSeverity["oracle-oval"] then ["ora", (.VendorSeverity["oracle-oval"] | if . == 1 then "L" elif . == 2 then "M" elif . == 3 then "H" elif . == 4 then "C" else "-" end), "https://linux.oracle.com/cve/\($cve).html"] elif .VendorSeverity.bitnami then ["bit", (.VendorSeverity.bitnami | if . == 1 then "L" elif . == 2 then "M" elif . == 3 then "H" elif . == 4 then "C" else "-" end), ""] elif .VendorSeverity.alma then ["alma", (.VendorSeverity.alma | if . == 1 then "L" elif . == 2 then "M" elif . == 3 then "H" elif . == 4 then "C" else "-" end), "https://errata.almalinux.org/"] elif .VendorSeverity.rocky then ["rky", (.VendorSeverity.rocky | if . == 1 then "L" elif . == 2 then "M" elif . == 3 then "H" elif . == 4 then "C" else "-" end), "https://errata.rockylinux.org/"] else ["-", "-", ""] end) as $vendor |
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
      echo "| Package | NVD | GitHub Advisories | CVE Published | Trivy Severity | Vendor Severity | Installed | Fixed | Fix? |"
      echo "|---------|-----|-------------------|---------------|----------------|-----------------|-----------|-------|------|"
    } >> "$report_file"

    jq -r '.Results[]? | select(.Type == "python-pkg") | .Vulnerabilities[]? |
      select(.Severity == "HIGH" or .Severity == "CRITICAL") |
      .VulnerabilityID as $cve |
      (if .VendorSeverity.nvd then ["nvd", (.VendorSeverity.nvd | if . == 1 then "L" elif . == 2 then "M" elif . == 3 then "H" elif . == 4 then "C" else "-" end), "https://nvd.nist.gov/vuln/detail/\($cve)"] elif .VendorSeverity.ghsa then ["ghsa", (.VendorSeverity.ghsa | if . == 1 then "L" elif . == 2 then "M" elif . == 3 then "H" elif . == 4 then "C" else "-" end), "https://github.com/advisories?query=\($cve)"] elif .VendorSeverity.redhat then ["rh", (.VendorSeverity.redhat | if . == 1 then "L" elif . == 2 then "M" elif . == 3 then "H" elif . == 4 then "C" else "-" end), "https://access.redhat.com/security/cve/\($cve)"] elif .VendorSeverity.amazon then ["amz", (.VendorSeverity.amazon | if . == 1 then "L" elif . == 2 then "M" elif . == 3 then "H" elif . == 4 then "C" else "-" end), "https://alas.aws.amazon.com/cve/html/\($cve).html"] elif .VendorSeverity["oracle-oval"] then ["ora", (.VendorSeverity["oracle-oval"] | if . == 1 then "L" elif . == 2 then "M" elif . == 3 then "H" elif . == 4 then "C" else "-" end), "https://linux.oracle.com/cve/\($cve).html"] elif .VendorSeverity.bitnami then ["bit", (.VendorSeverity.bitnami | if . == 1 then "L" elif . == 2 then "M" elif . == 3 then "H" elif . == 4 then "C" else "-" end), ""] elif .VendorSeverity.alma then ["alma", (.VendorSeverity.alma | if . == 1 then "L" elif . == 2 then "M" elif . == 3 then "H" elif . == 4 then "C" else "-" end), "https://errata.almalinux.org/"] elif .VendorSeverity.rocky then ["rky", (.VendorSeverity.rocky | if . == 1 then "L" elif . == 2 then "M" elif . == 3 then "H" elif . == 4 then "C" else "-" end), "https://errata.rockylinux.org/"] else ["-", "-", ""] end) as $vendor |
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

echo "✓ Enhanced vulnerability report created: $report_file"
