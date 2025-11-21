#!/usr/bin/env bash
#
# save-grype-results.sh
#
# Utility script to locate and save Grype scan results to a consistent filename.
# The anchore/scan-action outputs results to various locations depending on configuration.
#
# Usage:
#   save-grype-results.sh [output_filename]
#
# Arguments:
#   output_filename: Desired output filename (default: grype-results.sarif or grype-results.json)
#
# Environment Variables:
#   GRYPE_OUTPUT_FORMAT: Output format - 'sarif' or 'json' (default: sarif)
#
# Outputs:
#   - Grype results saved to specified filename
#   - Exit code 0 on success, 1 if no results found

set -e

# Configuration
OUTPUT_FORMAT="${GRYPE_OUTPUT_FORMAT:-sarif}"
OUTPUT_FILE="${1:-grype-results.${OUTPUT_FORMAT}}"

echo "🔍 Locating Grype scan results (format: ${OUTPUT_FORMAT})..."

# Determine file extension based on format
if [ "$OUTPUT_FORMAT" = "sarif" ]; then
  # Try to find SARIF output in common locations
  if [ -f "results.sarif" ]; then
    mv results.sarif "$OUTPUT_FILE"
    echo "✓ Grype SARIF results saved to $OUTPUT_FILE"
    exit 0
  elif [ -f "anchore-scan-results.sarif" ]; then
    mv anchore-scan-results.sarif "$OUTPUT_FILE"
    echo "✓ Grype SARIF results saved to $OUTPUT_FILE"
    exit 0
  elif [ -f "$OUTPUT_FILE" ]; then
    echo "✓ Grype SARIF results already at $OUTPUT_FILE"
    exit 0
  else
    echo "⚠ Grype SARIF output file not found in expected locations"
    echo "Checking for any SARIF files created by Grype:"
    find . -name "*.sarif" -type f -mmin -5 | grep -v node_modules || true
    exit 1
  fi
elif [ "$OUTPUT_FORMAT" = "json" ]; then
  # Try to find JSON output in common locations
  if [ -f "results.json" ]; then
    mv results.json "$OUTPUT_FILE"
    echo "✓ Grype JSON results saved to $OUTPUT_FILE"
    exit 0
  elif [ -f "anchore-scan-results.json" ]; then
    mv anchore-scan-results.json "$OUTPUT_FILE"
    echo "✓ Grype JSON results saved to $OUTPUT_FILE"
    exit 0
  elif [ -f "$OUTPUT_FILE" ]; then
    echo "✓ Grype JSON results already at $OUTPUT_FILE"
    exit 0
  else
    echo "⚠ Grype JSON output file not found in expected locations"
    echo "Checking for any JSON files created by Grype:"
    find . -name "*.json" -type f -mmin -5 | grep -v node_modules || true
    exit 1
  fi
else
  echo "❌ Unknown output format: $OUTPUT_FORMAT"
  echo "Supported formats: sarif, json"
  exit 1
fi
