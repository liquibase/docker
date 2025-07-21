#!/bin/bash
set -euo pipefail

REPO_NAME="$1"
DOCKERHUB_NAMESPACE=liquibase
MAX_PARALLEL_JOBS=${MAX_PARALLEL_JOBS:-4}
MAX_TAGS=${MAX_TAGS:-20}  # Limit recent tags only

echo "🔍 Scanning recent tags for $DOCKERHUB_NAMESPACE/$REPO_NAME (max: $MAX_TAGS tags)"

mkdir -p sarif-outputs
touch trivy-failures.txt

# Pre-install and warm up Trivy DB
echo "📦 Installing Trivy and warming up database..."
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
# Download and cache the vulnerability database once
trivy image --download-db-only
trivy --version

fetch_recent_tags() {
  local url="https://hub.docker.com/v2/repositories/${DOCKERHUB_NAMESPACE}/${REPO_NAME}/tags?page_size=100&ordering=-last_updated"
  local count=0
  
  while [ -n "$url" ] && [ $count -lt $MAX_TAGS ]; do
    response=$(curl -s "$url")
    
    # Parse tags and return the most recent ones up to MAX_TAGS
    while IFS= read -r tag; do
      if [ $count -ge $MAX_TAGS ]; then break; fi
      if [ -z "$tag" ] || [ "$tag" = "null" ]; then continue; fi
      
      echo "$tag"
      ((count++))
    done < <(echo "$response" | jq -r '.results[].name // empty')
    
    url=$(echo "$response" | jq -r '.next')
    [ "$url" = "null" ] && break
  done
}

scan_tag() {
  local tag=$1
  local image="docker.io/${DOCKERHUB_NAMESPACE}/${REPO_NAME}:${tag}"
  local sarif="sarif-outputs/${REPO_NAME}--${tag//\//-}.sarif"

  echo "🧪 [$$] Scanning $image"
  
  # Use --cache-dir for faster subsequent scans
  if docker pull "$image" 2>/dev/null; then
    if ! trivy image \
      --cache-dir /tmp/trivy-cache \
      --vuln-type os,library \
      --scanners vuln \
      --format sarif \
      --output "$sarif" \
      --severity HIGH,CRITICAL \
      --exit-code 1 \
      --timeout 10m \
      "$image" 2>/dev/null; then
      echo "$image" >> trivy-failures.txt
    fi
  else
    echo "❌ Failed to pull $image"
  fi

  # Clean up immediately to save disk space
  docker image rm "$image" 2>/dev/null || true
}

# Export function for parallel execution
export -f scan_tag
export DOCKERHUB_NAMESPACE REPO_NAME

# Create parallel job control
echo "🚀 Starting parallel scans (max $MAX_PARALLEL_JOBS jobs)..."

# Get tags and run parallel scans
fetch_recent_tags | while IFS= read -r tag; do
  if [[ "$tag" =~ ^[a-zA-Z0-9._-]+$ ]]; then
    # Use xargs for parallel processing with job limit
    echo "$tag"
  else
    echo "⚠️ Skipping invalid tag: $tag" >&2
  fi
done | xargs -n 1 -P "$MAX_PARALLEL_JOBS" -I {} bash -c 'scan_tag "$@"' _ {}

# Clean up Docker to free space
docker system prune -f -a --volumes 2>/dev/null || true

echo "✅ Scanning complete for $REPO_NAME"

# === SARIF upload (only if files exist) ===
if ls sarif-outputs/*.sarif 1> /dev/null 2>&1; then
  echo "::group::Upload SARIF results"
  
  # Combine SARIF files more efficiently
  combined_sarif=$(find sarif-outputs -name "*.sarif" -exec cat {} \; | jq -s '{
    version: "2.1.0",
    runs: map(select(.runs) | .runs[])
  }')
  
  gh api \
    --method POST \
    -H "Accept: application/vnd.github+json" \
    /repos/${GITHUB_REPOSITORY}/code-scanning/sarifs \
    -f commit_sha="${GITHUB_SHA}" \
    -f ref="${GITHUB_REF}" \
    --input <(echo "$combined_sarif") \
    -F checkout_uri="file://$(pwd)" \
    -F started_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo "::endgroup::"
else
  echo "⚠️ No SARIF files generated"
fi

# === Upload scan artifacts (more selective) ===
echo "::group::Upload artifacts"
mkdir -p artifacts
if [ -d sarif-outputs ] && [ "$(ls -A sarif-outputs)" ]; then
  # Only upload non-empty SARIF files
  find sarif-outputs -name "*.sarif" -size +0 -exec cp {} artifacts/ \;
fi
cp trivy-failures.txt artifacts/ 2>/dev/null || true

# Create summary file
echo "Scanned repository: $REPO_NAME" > artifacts/scan-summary.txt
echo "Tags scanned: $(ls sarif-outputs/*.sarif 2>/dev/null | wc -l)" >> artifacts/scan-summary.txt
echo "Scan date: $(date)" >> artifacts/scan-summary.txt
echo "::endgroup::"

# === Print scan summary ===
if [[ -s trivy-failures.txt ]]; then
  echo "❌ The following images had HIGH/CRITICAL vulnerabilities:"
  cat trivy-failures.txt
  exit 1
else
  echo "✅ No HIGH or CRITICAL vulnerabilities found."
fi