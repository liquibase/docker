#!/usr/bin/env bash
#
# check-file-exists.sh
#
# Utility script to check if a file exists and optionally set GitHub Actions output.
# This is commonly used to check for SARIF or JSON scan results before uploading.
#
# Usage:
#   check-file-exists.sh <filename> [output_name]
#
# Arguments:
#   filename: Path to the file to check
#   output_name: Name for GitHub Actions output variable (default: 'exists')
#
# Environment Variables:
#   GITHUB_OUTPUT: GitHub Actions output file path (optional)
#
# Outputs:
#   - GitHub Actions output: <output_name>=true or false
#   - Exit code 0 (always succeeds)

set -e

# Arguments
FILENAME="${1:?Error: Filename required}"
OUTPUT_NAME="${2:-exists}"

echo "🔍 Checking if file exists: ${FILENAME}"

# Check if file exists
if [ -f "$FILENAME" ]; then
  echo "✓ File exists: ${FILENAME}"
  EXISTS="true"
else
  echo "⚠ File not found: ${FILENAME}"
  EXISTS="false"
fi

# Set GitHub Actions output if available
if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "${OUTPUT_NAME}=${EXISTS}" >> "$GITHUB_OUTPUT"
  echo "✓ Set GitHub output: ${OUTPUT_NAME}=${EXISTS}"
else
  echo "Result: ${EXISTS}"
fi

exit 0
