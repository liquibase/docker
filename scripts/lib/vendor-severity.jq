# vendor-severity.jq
# Shared jq functions for extracting vendor severity data
#
# Usage: jq -L scripts/lib 'include "vendor-severity"; ...'
# Or inline with: jq --slurpfile not needed, just import the filter

# Converts numeric severity (1=LOW, 2=MEDIUM, 3=HIGH, 4=CRITICAL) to letter
def severity_letter:
  if . == 1 then "L"
  elif . == 2 then "M"
  elif . == 3 then "H"
  elif . == 4 then "C"
  else "-"
  end;

# Extracts vendor severity as [prefix, letter, url] array
# Requires $cve to be in scope
def vendor_severity($cve):
  if .VendorSeverity.nvd then
    ["nvd", (.VendorSeverity.nvd | severity_letter), "https://nvd.nist.gov/vuln/detail/\($cve)"]
  elif .VendorSeverity.ghsa then
    ["ghsa", (.VendorSeverity.ghsa | severity_letter), "https://github.com/advisories?query=\($cve)"]
  elif .VendorSeverity.redhat then
    ["rh", (.VendorSeverity.redhat | severity_letter), "https://access.redhat.com/security/cve/\($cve)"]
  elif .VendorSeverity.amazon then
    ["amz", (.VendorSeverity.amazon | severity_letter), "https://alas.aws.amazon.com/cve/html/\($cve).html"]
  elif .VendorSeverity["oracle-oval"] then
    ["ora", (.VendorSeverity["oracle-oval"] | severity_letter), "https://linux.oracle.com/cve/\($cve).html"]
  elif .VendorSeverity.bitnami then
    ["bit", (.VendorSeverity.bitnami | severity_letter), ""]
  elif .VendorSeverity.alma then
    ["alma", (.VendorSeverity.alma | severity_letter), "https://errata.almalinux.org/"]
  elif .VendorSeverity.rocky then
    ["rky", (.VendorSeverity.rocky | severity_letter), "https://errata.rockylinux.org/"]
  else
    ["-", "-", ""]
  end;

# Format vendor severity for markdown display
# Returns "[prefix:letter](url)" if url exists, "prefix:letter" if no url, or "-" if no vendor data
def format_vendor($vendor):
  if $vendor[0] == "-" then
    "-"
  elif $vendor[2] != "" then
    "[\($vendor[0]):\($vendor[1])](\($vendor[2]))"
  else
    "\($vendor[0]):\($vendor[1])"
  end;
