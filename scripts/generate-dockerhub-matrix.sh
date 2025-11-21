#!/usr/bin/env bash
#
# generate-dockerhub-matrix.sh
#
# Generates a JSON matrix of Docker images and tags to scan from Docker Hub.
# Fetches recent tags for both liquibase/liquibase and liquibase/liquibase-secure.
#
# Usage:
#   generate-dockerhub-matrix.sh [max_tags]
#
# Arguments:
#   max_tags: Maximum number of tags to scan per image (default: 10)
#
# Environment Variables:
#   MAX_TAGS: Maximum tags per image (overrides argument)
#
# Outputs:
#   - JSON matrix written to stdout and $GITHUB_OUTPUT if available
#   - Format: {"include":[{"image":"...","tag":"..."},...]}"

set -e

# Configuration
MAX_TAGS="${MAX_TAGS:-${1:-10}}"

echo "Generating matrix for scanning with max $MAX_TAGS tags per image..." >&2

MATRIX_INCLUDE="["
FIRST=true

for IMAGE in "liquibase/liquibase" "liquibase/liquibase-secure"; do
  echo "Getting tags for $IMAGE..." >&2
  REPO=$(basename "$IMAGE")
  TAGS=""
  URL="https://hub.docker.com/v2/namespaces/liquibase/repositories/${REPO}/tags?page_size=100"

  while [ -n "$URL" ]; do
    RESPONSE=$(curl -s "$URL")

    # Only include semantic version tags (with optional -alpine or -latest suffix)
    TAG_REGEX='^[0-9]+\.[0-9]+(\.[0-9]+)?(-alpine|-latest)?$'
    NEW_TAGS=$(echo "$RESPONSE" | jq -r '.results[] | select(.tag_status == "active") | .name' | grep -E "$TAG_REGEX" || true)
    TAGS=$(echo -e "$TAGS\n$NEW_TAGS" | sort -Vu)

    # Filter out minor version tags if we have the full version
    # e.g., if we have 4.28.0, skip 4.28
    TAGS=$(echo "$TAGS" | awk '
      {
        tags[NR] = $0
        if (match($0, /^([0-9]+)\.([0-9]+)\.([0-9]+)(-alpine|-latest)?$/, m)) {
          full = m[1] "." m[2] "." m[3] (m[4] ? m[4] : "")
          has_full[full] = 1
        }
      }
      END {
        for (i = 1; i <= NR; i++) {
          tag = tags[i]
          if (match(tag, /^([0-9]+)\.([0-9]+)(-alpine|-latest)?$/, m)) {
            short = m[1] "." m[2] ".0" (m[3] ? m[3] : "")
            if (has_full[short]) continue
          }
          print tag
        }
      }
    ')

    # Get next page URL
    URL=$(echo "$RESPONSE" | jq -r '.next')
    [ "$URL" = "null" ] && break
  done

  # Get most recent tags (reverse sort and take first N)
  TAGS=$(echo "$TAGS" | tac | head -n "$MAX_TAGS")

  # Build matrix JSON
  while IFS= read -r tag; do
    if [ -n "$tag" ]; then
      if [ "$FIRST" = true ]; then
        MATRIX_INCLUDE="${MATRIX_INCLUDE}{\"image\":\"$IMAGE\",\"tag\":\"$tag\"}"
        FIRST=false
      else
        MATRIX_INCLUDE="${MATRIX_INCLUDE},{\"image\":\"$IMAGE\",\"tag\":\"$tag\"}"
      fi
    fi
  done <<< "$TAGS"
done

MATRIX_INCLUDE="${MATRIX_INCLUDE}]"
MATRIX="{\"include\":$MATRIX_INCLUDE}"

echo "Generated matrix: $MATRIX" >&2

# Output to GitHub Actions if running in CI
if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "matrix=$MATRIX" >> "$GITHUB_OUTPUT"
fi

# Always output to stdout for testing/debugging
echo "$MATRIX"
