#!/usr/bin/env bash
#
# convert-scan-results.sh
#
# Converts Trivy JSON scan results to SARIF format and analyzes vulnerability counts.
# Requires Trivy CLI to be installed.
#
# Usage:
#   convert-scan-results.sh
#
# Expected Input Files:
#   - trivy-surface.json: Trivy surface scan results (optional)
#   - trivy-deep.json: Trivy deep scan results (optional)
#   - grype-results.json: Grype JSON results (optional)
#
# Outputs:
#   - trivy-surface.sarif: Converted SARIF format
#   - trivy-deep.sarif: Converted SARIF format
#   - Environment variables: surface_vulns, deep_vulns, grype_vulns, total_vulns
#   - Exit code 0 (always succeeds to allow workflow to continue)

set +e  # Don't fail immediately

echo "🔍 Converting scan results to SARIF format..."
echo ""
echo "Available scan result files:"
ls -lh *.sarif *.json 2>/dev/null || echo "No scan result files found"
echo ""

# Initialize counters
surface_vulns=0
deep_vulns=0
grype_vulns=0

# Convert Trivy surface scan results
if [ -f trivy-surface.json ]; then
  trivy convert --format sarif --output trivy-surface.sarif trivy-surface.json
  surface_vulns=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "HIGH" or .Severity == "CRITICAL")] | length' trivy-surface.json 2>/dev/null || echo 0)
  echo "✓ Trivy Surface Scan: $surface_vulns HIGH/CRITICAL vulnerabilities"
else
  echo "⚠ Trivy Surface Scan: JSON file not found"
fi

# Convert Trivy deep scan results
if [ -f trivy-deep.json ]; then
  trivy convert --format sarif --output trivy-deep.sarif trivy-deep.json
  deep_vulns=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "HIGH" or .Severity == "CRITICAL")] | length' trivy-deep.json 2>/dev/null || echo 0)
  echo "✓ Trivy Deep Scan: $deep_vulns HIGH/CRITICAL vulnerabilities"
else
  echo "⚠ Trivy Deep Scan: JSON file not found"
fi

# Process Grype results
if [ -f grype-results.json ]; then
  # Count vulnerabilities from JSON
  grype_vulns=$(jq '[.matches[]? | select(.vulnerability.severity == "High" or .vulnerability.severity == "Critical")] | length' grype-results.json 2>/dev/null || echo 0)
  echo "✓ Grype SBOM Scan: $grype_vulns HIGH/CRITICAL vulnerabilities"
else
  echo "⚠ Grype SBOM Scan: JSON file not found (scan may have failed or SBOM was empty)"
fi

total_vulns=$((surface_vulns + deep_vulns + grype_vulns))
echo ""
echo "📊 Total HIGH/CRITICAL vulnerabilities found: $total_vulns"

# Print detailed table if vulnerabilities found
if [ $total_vulns -gt 0 ]; then
  echo ""
  echo "==== Trivy Surface Scan Vulnerabilities ===="
  if [ -f trivy-surface.json ] && [ $surface_vulns -gt 0 ]; then
    trivy convert --format table trivy-surface.json
  fi

  echo ""
  echo "==== Trivy Deep Scan Vulnerabilities (Nested JARs) ===="
  if [ -f trivy-deep.json ] && [ $deep_vulns -gt 0 ]; then
    trivy convert --format table trivy-deep.json
  fi
fi

# Export to GitHub Actions environment if available
if [ -n "${GITHUB_ENV:-}" ]; then
  echo "surface_vulns=$surface_vulns" >> "$GITHUB_ENV"
  echo "deep_vulns=$deep_vulns" >> "$GITHUB_ENV"
  echo "grype_vulns=$grype_vulns" >> "$GITHUB_ENV"
  echo "total_vulns=$total_vulns" >> "$GITHUB_ENV"
fi

echo "✅ Conversion complete"
exit 0
