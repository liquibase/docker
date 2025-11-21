#!/usr/bin/env bash
#
# analyze-scan-results.sh
#
# Analyzes and combines vulnerability scan results from multiple scanners (Trivy, Grype).
# Generates detailed reports and determines overall scan status.
#
# Usage:
#   analyze-scan-results.sh
#
# Environment Variables:
#   EXTRACT_DIR: Directory containing jar-mapping.txt (default: /tmp/extracted-deps)
#   IMAGE_NAME: Name of the image being scanned
#   IMAGE_SUFFIX: Suffix for the image variant (e.g., -alpine)
#
# Expected Input Files:
#   - trivy-surface.json: Trivy surface scan results
#   - trivy-deep.json: Trivy deep scan results
#   - grype-results.sarif: Grype SARIF results
#
# Outputs:
#   - vulnerability-report-enhanced.md: Detailed vulnerability report
#   - scan-summary.txt: Summary of scan results
#   - Exit code 1 if vulnerabilities found, 0 otherwise

set +e  # Don't fail immediately - we want to collect all results

EXTRACT_DIR="${EXTRACT_DIR:-/tmp/extracted-deps}"
IMAGE_NAME="${IMAGE_NAME:-unknown}"
IMAGE_SUFFIX="${IMAGE_SUFFIX:-}"

echo "🔍 Analyzing scan results..."
echo ""
echo "Available scan result files:"
ls -lh *.sarif *.json 2>/dev/null || echo "No scan result files found"
echo ""

# Count vulnerabilities from each scanner (using JSON for accuracy)
surface_vulns=0
deep_vulns=0
grype_vulns=0

if [ -f trivy-surface.json ]; then
  surface_vulns=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "HIGH" or .Severity == "CRITICAL")] | length' trivy-surface.json 2>/dev/null || echo 0)
  echo "✓ Trivy Surface Scan: $surface_vulns HIGH/CRITICAL vulnerabilities"
else
  echo "⚠ Trivy Surface Scan: JSON file not found"
fi

if [ -f trivy-deep.json ]; then
  deep_vulns=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "HIGH" or .Severity == "CRITICAL")] | length' trivy-deep.json 2>/dev/null || echo 0)
  echo "✓ Trivy Deep Scan: $deep_vulns HIGH/CRITICAL vulnerabilities"
else
  echo "⚠ Trivy Deep Scan: JSON file not found"
fi

if [ -f grype-results.sarif ]; then
  grype_vulns=$(jq '[.runs[].results[]? | select(.level == "error" or .level == "warning")] | length' grype-results.sarif 2>/dev/null || echo 0)
  echo "✓ Grype SBOM Scan: $grype_vulns HIGH/CRITICAL vulnerabilities"
else
  echo "⚠ Grype SBOM Scan: SARIF file not found (scan may have failed or SBOM was empty)"
fi

total_vulns=$((surface_vulns + deep_vulns + grype_vulns))
echo ""
echo "📊 Total HIGH/CRITICAL vulnerabilities found: $total_vulns"

# Create GitHub Actions Summary if running in GitHub Actions
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  {
    echo "## 🛡️ Vulnerability Scan Results for \`${IMAGE_NAME}${IMAGE_SUFFIX}\`"
    echo ""
    echo "**Total HIGH/CRITICAL Vulnerabilities: $total_vulns**"
    echo ""
    echo "| Scanner | Vulnerabilities | Status |"
    echo "|---------|-----------------|--------|"
    echo "| 🔍 Trivy Surface (OS + Top-level) | $surface_vulns | $([ $surface_vulns -eq 0 ] && echo '✅' || echo '⚠️') |"
    echo "| 🔎 Trivy Deep (Nested JARs + Python) | $deep_vulns | $([ $deep_vulns -eq 0 ] && echo '✅' || echo '⚠️') |"
    echo "| 📋 Grype (SBOM-based) | $grype_vulns | $([ $grype_vulns -eq 0 ] && echo '✅' || echo '⚠️') |"
    echo ""
  } >> "$GITHUB_STEP_SUMMARY"

  # Add detailed vulnerability tables using JSON format (more reliable than SARIF)
  if [ $surface_vulns -gt 0 ] && [ -f trivy-surface.json ]; then
    {
      echo "### 🔍 Trivy Surface Scan Details"
      echo ""
      echo "| Package | Vulnerability | Severity | Installed | Fixed |"
      echo "|---------|---------------|----------|-----------|-------|"
    } >> "$GITHUB_STEP_SUMMARY"

    jq -r '.Results[]?.Vulnerabilities[]? | select(.Severity == "HIGH" or .Severity == "CRITICAL") |
      "| \(.PkgName) | \(.VulnerabilityID) | \(.Severity) | \(.InstalledVersion) | \(.FixedVersion // "N/A") |"' \
      trivy-surface.json 2>/dev/null | head -20 >> "$GITHUB_STEP_SUMMARY" || echo "| Error parsing results | - | - | - | - |" >> "$GITHUB_STEP_SUMMARY"

    echo "" >> "$GITHUB_STEP_SUMMARY"
  fi

  if [ $deep_vulns -gt 0 ] && [ -f trivy-deep.json ]; then
    {
      echo "### 🔎 Trivy Deep Scan Details (Nested JARs & Python)"
      echo ""
      echo "| Parent JAR | Package | Vulnerability | Severity | Installed | Fixed |"
      echo "|------------|---------|---------------|----------|-----------|-------|"
    } >> "$GITHUB_STEP_SUMMARY"

    # Process each vulnerability and look up parent JAR from mapping file
    # First, collect all rows into a temp file, then deduplicate
    temp_table="/tmp/vuln-table-$$.txt"
    > "$temp_table"  # Clear temp file

    jq -r '.Results[]? | .Target as $target | .Vulnerabilities[]? |
      select(.Severity == "HIGH" or .Severity == "CRITICAL") |
      "\($target)|\(.PkgPath // "")|\(.PkgName)|\(.VulnerabilityID)|\(.Severity)|\(.InstalledVersion)|\(.FixedVersion // "N/A")"' \
      trivy-deep.json 2>/dev/null | while IFS='|' read -r target pkgpath pkg vuln severity installed fixed; do

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

      echo "| $parent_jar | $pkg | $vuln | $severity | $installed | $fixed |" >> "$temp_table"
    done

    # Deduplicate and add to summary (limit to 40 entries)
    sort -u "$temp_table" | head -40 >> "$GITHUB_STEP_SUMMARY"
    rm -f "$temp_table"

    echo "" >> "$GITHUB_STEP_SUMMARY"
  fi

  if [ $grype_vulns -gt 0 ] && [ -f grype-results.sarif ]; then
    {
      echo "### 📋 Grype SBOM Scan Details"
      echo ""
      echo "| Package | Vulnerability | Severity | Installed | Fixed |"
      echo "|---------|---------------|----------|-----------|-------|"
    } >> "$GITHUB_STEP_SUMMARY"

    # Grype SARIF has different structure
    jq -r '.runs[].results[] |
      (.ruleId // "N/A") as $cve |
      (try (.properties.packageName // .locations[0].logicalLocations[0].name) // "N/A") as $pkg |
      (.level // "unknown") as $severity |
      (try (.properties.installedVersion // "N/A") catch "N/A") as $installed |
      (try (.properties.fixedVersion // "N/A") catch "N/A") as $fixed |
      "| \($pkg) | \($cve) | \($severity | ascii_upcase) | \($installed) | \($fixed) |"' \
      grype-results.sarif 2>/dev/null | head -20 >> "$GITHUB_STEP_SUMMARY" || echo "| Error parsing results | - | - | - | - |" >> "$GITHUB_STEP_SUMMARY"

    echo "" >> "$GITHUB_STEP_SUMMARY"
  fi

  # Add scanner information
  {
    echo "---"
    echo ""
    echo "### 📖 Scanner Information"
    echo ""
    echo "- **Trivy Surface**: Scans OS packages and top-level libraries"
    echo "- **Trivy Deep**: Extracts and scans nested Spring Boot JARs (BOOT-INF/lib) and GraalVM Python packages"
    echo "- **Grype**: SBOM-based validation for comprehensive dependency analysis"
    echo ""
    echo "💡 **Note**: Deep scan detects vulnerabilities in nested dependencies that standard scans miss."
  } >> "$GITHUB_STEP_SUMMARY"
fi

# Create combined summary file
cat > scan-summary.txt <<EOF
# Vulnerability Scan Summary - ${IMAGE_NAME}${IMAGE_SUFFIX}

## Scan Results
- **Trivy Surface Scan**: $surface_vulns vulnerabilities
- **Trivy Deep Scan (Nested JARs)**: $deep_vulns vulnerabilities
- **Grype SBOM Scan**: $grype_vulns vulnerabilities
- **Total**: $total_vulns HIGH/CRITICAL vulnerabilities

## Scanner Details
- Trivy Surface: OS packages and top-level libraries
- Trivy Deep: Extracted Spring Boot nested JARs and GraalVM Python packages
- Grype: SBOM-based comprehensive dependency analysis
EOF

echo "Scan summary created: scan-summary.txt"

# Create enhanced vulnerability report with parent JAR mapping
report_file="vulnerability-report-enhanced.md"

{
  echo "# Enhanced Vulnerability Report"
  echo ""
  echo "**Image**: \`${IMAGE_NAME}${IMAGE_SUFFIX}\`"
  echo "**Build SHA**: \`${GITHUB_SHA:-N/A}\`"
  echo "**Scan Date**: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  echo ""
  echo "## Summary"
  echo ""
  echo "| Scanner | HIGH/CRITICAL Vulnerabilities |"
  echo "|---------|-------------------------------|"
  echo "| Trivy Surface (OS + Top-level) | $surface_vulns |"
  echo "| Trivy Deep (Nested JARs + Python) | $deep_vulns |"
  echo "| Grype (SBOM-based) | $grype_vulns |"
  echo "| **Total** | **$total_vulns** |"
  echo ""
} > "$report_file"

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
    echo "| Parent JAR | Nested JAR | Vulnerability | Severity | Installed | Fixed |"
    echo "|------------|------------|---------------|----------|-----------|-------|"
  } >> "$report_file"

  # Process each vulnerability and match with parent JAR
  jq -r '.Results[]? | .Target as $target | .Vulnerabilities[]? |
    select(.Severity == "HIGH" or .Severity == "CRITICAL") |
    "\($target)|\(.PkgName)|\(.VulnerabilityID)|\(.Severity)|\(.InstalledVersion)|\(.FixedVersion // "-")"' \
    trivy-deep.json 2>/dev/null | while IFS='|' read -r target pkg vuln severity installed fixed; do

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

    echo "| $parent_jar | $jar_file | $vuln | $severity | $installed | $fixed |" >> "$report_file"
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
      echo "| Package | Vulnerability | Severity | Installed | Fixed |"
      echo "|---------|---------------|----------|-----------|-------|"
    } >> "$report_file"

    jq -r '.Results[]? | select(.Type == "python-pkg") | .Vulnerabilities[]? |
      select(.Severity == "HIGH" or .Severity == "CRITICAL") |
      "\(.PkgName)|\(.VulnerabilityID)|\(.Severity)|\(.InstalledVersion)|\(.FixedVersion // "-")"' \
      trivy-deep.json 2>/dev/null | while IFS='|' read -r pkg vuln severity installed fixed; do
      echo "| $pkg | $vuln | $severity | $installed | $fixed |" >> "$report_file"
    done

    echo "" >> "$report_file"
  fi
fi

echo "✓ Enhanced vulnerability report created: $report_file"

# Exit with error if vulnerabilities found
if [ $total_vulns -gt 0 ]; then
  echo "❌ Vulnerabilities detected - failing build"
  exit 1
else
  echo "✅ No HIGH/CRITICAL vulnerabilities found"
  exit 0
fi
