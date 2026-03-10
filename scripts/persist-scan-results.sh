#!/usr/bin/env bash
#
# persist-scan-results.sh
#
# Persists vulnerability scan results to the scan-results branch.
# Called after the vulnerability-scan matrix job completes.
# Downloads scan artifacts and commits them to a persistent branch
# so the Liquibase Security dashboard can read them via GitHub Contents API.
#
# Usage:
#   persist-scan-results.sh <artifacts-dir>
#
# Arguments:
#   artifacts-dir: Directory containing downloaded scan artifacts.
#                  Each subdirectory is named vulnerability-report-<image>-<tag>
#                  and contains trivy-surface.json, trivy-deep.json, grype-results.json.
#
# Environment Variables:
#   GITHUB_REPOSITORY: owner/repo (set by GitHub Actions)
#   GITHUB_SERVER_URL: GitHub server URL (set by GitHub Actions)
#   GITHUB_RUN_ID:     Workflow run ID (set by GitHub Actions)
#
# Branch structure:
#   scan-results/
#     manifest.json
#     <org>/<image>/<tag>/
#       trivy-surface.json
#       trivy-deep.json
#       grype-results.json
#       metadata.json

set -euo pipefail

ARTIFACTS_DIR="${1:?Usage: persist-scan-results.sh <artifacts-dir>}"
BRANCH="scan-results"
SCANNED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

if [ ! -d "$ARTIFACTS_DIR" ]; then
  echo "Error: artifacts directory not found: $ARTIFACTS_DIR" >&2
  exit 1
fi

# Count artifact directories
ARTIFACT_COUNT=$(find "$ARTIFACTS_DIR" -mindepth 1 -maxdepth 1 -type d -name "vulnerability-report-*" | wc -l | tr -d ' ')
if [ "$ARTIFACT_COUNT" -eq 0 ]; then
  echo "No scan artifacts found in $ARTIFACTS_DIR" >&2
  exit 0
fi

echo "Found $ARTIFACT_COUNT scan artifact(s) to persist"

# --- Set up worktree for the scan-results branch ---

WORKTREE_DIR=$(mktemp -d)
trap 'rm -rf "$WORKTREE_DIR"' EXIT

# Check if the branch exists on remote
if git ls-remote --exit-code origin "refs/heads/$BRANCH" >/dev/null 2>&1; then
  git fetch origin "$BRANCH"
  git worktree add "$WORKTREE_DIR" "origin/$BRANCH"
  cd "$WORKTREE_DIR"
  git checkout -B "$BRANCH" "origin/$BRANCH"
else
  # Create orphan branch
  git worktree add --detach "$WORKTREE_DIR"
  cd "$WORKTREE_DIR"
  git checkout --orphan "$BRANCH"
  git rm -rf . 2>/dev/null || true
  echo '{"lastUpdated":"","images":{}}' > manifest.json
  git add manifest.json
  git commit -m "Initialize scan-results branch"
fi

# --- Load existing manifest ---

if [ -f manifest.json ]; then
  MANIFEST=$(cat manifest.json)
else
  MANIFEST='{"lastUpdated":"","images":{}}'
fi

# --- Process each artifact ---

for ARTIFACT_PATH in "$ARTIFACTS_DIR"/vulnerability-report-*; do
  [ -d "$ARTIFACT_PATH" ] || continue
  ARTIFACT_NAME=$(basename "$ARTIFACT_PATH")

  # Parse image and tag from artifact name: vulnerability-report-<org>-<image>-<tag>
  # The reusable workflow sanitizes: tr '/' '-'
  # So liquibase/liquibase:5.0.1 becomes vulnerability-report-liquibase-liquibase-5.0.1
  # We need to reconstruct org/image and tag
  SUFFIX="${ARTIFACT_NAME#vulnerability-report-}"

  # The tag is the last segment after the last hyphen that looks like a version
  # Strategy: try known image prefixes first
  IMAGE=""
  TAG=""
  for PREFIX in "liquibase-liquibase-secure" "liquibase-liquibase"; do
    if [[ "$SUFFIX" == "$PREFIX-"* ]]; then
      TAG="${SUFFIX#"$PREFIX-"}"
      IMAGE="${PREFIX}"
      break
    fi
  done

  if [ -z "$IMAGE" ] || [ -z "$TAG" ]; then
    echo "Warning: could not parse artifact name: $ARTIFACT_NAME, skipping" >&2
    continue
  fi

  # Convert sanitized image name back to path: liquibase-liquibase -> liquibase/liquibase
  # liquibase-liquibase-secure -> liquibase/liquibase-secure
  case "$IMAGE" in
    liquibase-liquibase-secure) IMAGE_PATH="liquibase/liquibase-secure" ;;
    liquibase-liquibase)        IMAGE_PATH="liquibase/liquibase" ;;
    *)
      echo "Warning: unknown image prefix: $IMAGE, skipping" >&2
      continue
      ;;
  esac

  DEST_DIR="$IMAGE_PATH/$TAG"
  mkdir -p "$DEST_DIR"

  echo "Persisting $IMAGE_PATH:$TAG"

  # Copy scan result files
  for FILE in trivy-surface.json trivy-deep.json grype-results.json; do
    if [ -f "$ARTIFACT_PATH/$FILE" ]; then
      cp "$ARTIFACT_PATH/$FILE" "$DEST_DIR/$FILE"
    fi
  done

  # Also check for grype-results.json variants (some workflows output grype-results.sarif too)
  # We only need the JSON

  # Create metadata.json
  cat > "$DEST_DIR/metadata.json" <<EOF
{
  "scannedAt": "$SCANNED_AT",
  "image": "$IMAGE_PATH",
  "tag": "$TAG",
  "workflowRunId": "${GITHUB_RUN_ID:-}"
}
EOF

  git add "$DEST_DIR/"

  # Update manifest in memory — add tag to image list if not already present
  MANIFEST=$(echo "$MANIFEST" | jq --arg img "$IMAGE_PATH" --arg tag "$TAG" '
    .images[$img] = ((.images[$img] // []) | if index($tag) then . else . + [$tag] end)
  ')
done

# --- Update manifest ---

MANIFEST=$(echo "$MANIFEST" | jq --arg ts "$SCANNED_AT" '.lastUpdated = $ts')

# Sort version tags in descending order for each image
MANIFEST=$(echo "$MANIFEST" | jq '
  .images |= with_entries(
    .value |= sort_by(split(".") | map(tonumber? // 0)) | reverse
  )
')

echo "$MANIFEST" | jq . > manifest.json
git add manifest.json

# --- Commit and push ---

if git diff --cached --quiet; then
  echo "No changes to commit"
  exit 0
fi

CHANGED_COUNT=$(git diff --cached --name-only | grep -c "metadata.json" || echo 0)
git commit -m "Update scan results ($CHANGED_COUNT version(s)) — $SCANNED_AT"
git push origin "$BRANCH"

echo "Persisted scan results to $BRANCH branch ($CHANGED_COUNT version(s))"
