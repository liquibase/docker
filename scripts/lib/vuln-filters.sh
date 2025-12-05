#!/usr/bin/env bash
#
# lib/vuln-filters.sh
#
# Shared jq filters and functions for vulnerability scanning scripts.
# Source this file to use the functions in other scripts.
#
# Usage:
#   source "$(dirname "$0")/lib/vuln-filters.sh"
#
# Available variables:
#   JQ_VENDOR_FILTER - jq filter that extracts vendor severity as $vendor array
#
# Available functions:
#   jq_trivy_surface_vulns  - Process Trivy surface scan vulnerabilities
#   jq_trivy_deep_vulns     - Process Trivy deep scan vulnerabilities (with target)
#   jq_trivy_python_vulns   - Process Python package vulnerabilities
#   format_vendor_display   - Format vendor severity for markdown display
#   format_fix_indicator    - Format Y/N as emoji

# Vendor severity jq filter - extracts [prefix, letter, url] array
# This is the core filter used by all Trivy vulnerability processing.
# Requires $cve to be defined in jq context before this filter.
# Result is stored in $vendor variable: [prefix, severity_letter, url]
#
# Supported vendors (in priority order):
#   nvd, ghsa, redhat, amazon, oracle-oval, bitnami, alma, rocky
#
# Usage in jq:
#   .VulnerabilityID as $cve | '"${JQ_VENDOR_FILTER}"' | ... use $vendor ...
#
readonly JQ_VENDOR_FILTER='
(if .VendorSeverity.nvd then
  ["nvd", (.VendorSeverity.nvd | if . == 1 then "L" elif . == 2 then "M" elif . == 3 then "H" elif . == 4 then "C" else "-" end), "https://nvd.nist.gov/vuln/detail/\($cve)"]
elif .VendorSeverity.ghsa then
  ["ghsa", (.VendorSeverity.ghsa | if . == 1 then "L" elif . == 2 then "M" elif . == 3 then "H" elif . == 4 then "C" else "-" end), "https://github.com/advisories?query=\($cve)"]
elif .VendorSeverity.redhat then
  ["rh", (.VendorSeverity.redhat | if . == 1 then "L" elif . == 2 then "M" elif . == 3 then "H" elif . == 4 then "C" else "-" end), "https://access.redhat.com/security/cve/\($cve)"]
elif .VendorSeverity.amazon then
  ["amz", (.VendorSeverity.amazon | if . == 1 then "L" elif . == 2 then "M" elif . == 3 then "H" elif . == 4 then "C" else "-" end), "https://alas.aws.amazon.com/cve/html/\($cve).html"]
elif .VendorSeverity["oracle-oval"] then
  ["ora", (.VendorSeverity["oracle-oval"] | if . == 1 then "L" elif . == 2 then "M" elif . == 3 then "H" elif . == 4 then "C" else "-" end), "https://linux.oracle.com/cve/\($cve).html"]
elif .VendorSeverity.bitnami then
  ["bit", (.VendorSeverity.bitnami | if . == 1 then "L" elif . == 2 then "M" elif . == 3 then "H" elif . == 4 then "C" else "-" end), ""]
elif .VendorSeverity.alma then
  ["alma", (.VendorSeverity.alma | if . == 1 then "L" elif . == 2 then "M" elif . == 3 then "H" elif . == 4 then "C" else "-" end), "https://errata.almalinux.org/"]
elif .VendorSeverity.rocky then
  ["rky", (.VendorSeverity.rocky | if . == 1 then "L" elif . == 2 then "M" elif . == 3 then "H" elif . == 4 then "C" else "-" end), "https://errata.rockylinux.org/"]
else
  ["-", "-", ""]
end) as $vendor'

# Process Trivy surface scan results and output pipe-delimited rows
# Output format: pkg|cve|cve_date|severity|vendor_prefix:letter|vendor_url|installed|fixed|has_fix
# Usage: jq_trivy_surface_vulns trivy-surface.json
jq_trivy_surface_vulns() {
  local input_file="$1"
  jq -r '.Results[]?.Vulnerabilities[]? | select(.Severity == "HIGH" or .Severity == "CRITICAL") |
    .VulnerabilityID as $cve |
    '"${JQ_VENDOR_FILTER}"' |
    "\(.PkgName)|\($cve)|\((.PublishedDate // "-") | split("T")[0])|\(.Severity)|\($vendor[0]):\($vendor[1])|\($vendor[2])|\(.InstalledVersion)|\(.FixedVersion // "-")|\(if (.FixedVersion // "") != "" then "Y" else "N" end)"' \
    "$input_file" 2>/dev/null
}

# Process Trivy deep scan results and output pipe-delimited rows with target
# Output format: target|pkg|cve|cve_date|severity|vendor_prefix:letter|vendor_url|installed|fixed|has_fix
# Usage: jq_trivy_deep_vulns trivy-deep.json
jq_trivy_deep_vulns() {
  local input_file="$1"
  jq -r '.Results[]? | .Target as $target | .Vulnerabilities[]? |
    select(.Severity == "HIGH" or .Severity == "CRITICAL") |
    .VulnerabilityID as $cve |
    '"${JQ_VENDOR_FILTER}"' |
    "\($target)|\(.PkgPath // "")|\(.PkgName)|\($cve)|\((.PublishedDate // "-") | split("T")[0])|\(.Severity)|\($vendor[0]):\($vendor[1])|\($vendor[2])|\(.InstalledVersion)|\(.FixedVersion // "-")|\(if (.FixedVersion // "") != "" then "Y" else "N" end)"' \
    "$input_file" 2>/dev/null
}

# Process Trivy Python package vulnerabilities
# Output format: pkg|cve|cve_date|severity|vendor_prefix:letter|vendor_url|installed|fixed|has_fix
# Usage: jq_trivy_python_vulns trivy-deep.json
jq_trivy_python_vulns() {
  local input_file="$1"
  jq -r '.Results[]? | select(.Type == "python-pkg") | .Vulnerabilities[]? |
    select(.Severity == "HIGH" or .Severity == "CRITICAL") |
    .VulnerabilityID as $cve |
    '"${JQ_VENDOR_FILTER}"' |
    "\(.PkgName)|\($cve)|\((.PublishedDate // "-") | split("T")[0])|\(.Severity)|\($vendor[0]):\($vendor[1])|\($vendor[2])|\(.InstalledVersion)|\(.FixedVersion // "-")|\(if (.FixedVersion // "") != "" then "Y" else "N" end)"' \
    "$input_file" 2>/dev/null
}

# Format vendor severity for markdown display
# Input: vendor_sev (e.g., "rh:H") and vendor_url
# Output: "[rh:H](url)" if url exists, "-" if no vendor data, else "rh:H"
# Usage: format_vendor_display "$vendor_sev" "$vendor_url"
format_vendor_display() {
  local vendor_sev="$1"
  local vendor_url="$2"
  # Handle no vendor data case (fallback returns "-:-")
  if [ "$vendor_sev" = "-:-" ]; then
    echo "-"
  elif [ -n "$vendor_url" ]; then
    echo "[$vendor_sev]($vendor_url)"
  else
    echo "$vendor_sev"
  fi
}

# Format fix indicator for markdown
# Input: "Y" or "N"
# Output: checkmark or x emoji
format_fix_indicator() {
  if [ "$1" = "Y" ]; then
    echo "✅"
  else
    echo "❌"
  fi
}
