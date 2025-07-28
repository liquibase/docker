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
  # Error output from docker pull is logged to docker-errors.log for debugging purposes
  if docker pull "$image" 2>>docker-errors.log; then
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
      echo "❌ VULNERABILITIES FOUND: $image"
      echo "$tag" >> trivy-failures.txt
    else
      echo "✅ CLEAN: $image"
    fi
  else
    echo "❌ Failed to pull $image"
    echo "PULL_FAILED:$tag" >> trivy-failures.txt
  fi

  # Clean up immediately to save disk space
  docker image rm "$image" 2>/dev/null || true
}

# Create parallel job control
echo "🚀 Starting parallel scans (max $MAX_PARALLEL_JOBS jobs)..."

# Get tags and filter valid ones into an array
valid_tags=()
while IFS= read -r tag; do
  if [[ "$tag" =~ ^[a-z0-9]+(?:[._-][a-z0-9]+)*$ ]]; then
    valid_tags+=("$tag")
  else
    echo "⚠️ Skipping invalid tag: $tag"
  fi
done < <(fetch_recent_tags)

echo "Found ${#valid_tags[@]} valid tags to scan"

# Process tags with controlled parallelism
active_jobs=0
for tag in "${valid_tags[@]}"; do
  # Start scan in background
  scan_tag "$tag" &
  
  ((active_jobs++))
  
  # Wait if we've reached the job limit
  if ((active_jobs >= MAX_PARALLEL_JOBS)); then
    wait -n  # Wait for any job to complete
    ((active_jobs--))
  fi
done

# Wait for all remaining jobs to complete
wait

echo "Completed scanning ${#valid_tags[@]} tags"

# Clean up Docker to free space
docker system prune -f -a --volumes 2>/dev/null || true

echo "✅ Scanning complete for $REPO_NAME"

# === ALWAYS create artifacts directory first ===
echo "::group::Prepare artifacts"
mkdir -p artifacts
echo "Created artifacts directory"

# === SARIF upload (only if files exist) ===
if ls sarif-outputs/*.sarif 1> /dev/null 2>&1; then
  echo "::group::Upload SARIF results"
  
  # Combine SARIF files more efficiently
  combined_sarif=$(find sarif-outputs -name "*.sarif" -exec cat {} \; | jq -s '{
    version: "2.1.0",
    runs: map(select(.runs) | .runs[])
  }')
  
  if [ -n "$GITHUB_REPOSITORY" ] && [ -n "$GITHUB_SHA" ] && [ -n "$GITHUB_REF" ]; then
    gh api \
      --method POST \
      -H "Accept: application/vnd.github+json" \
      /repos/${GITHUB_REPOSITORY}/code-scanning/sarifs \
      -f commit_sha="${GITHUB_SHA}" \
      -f ref="${GITHUB_REF}" \
      --input <(echo "$combined_sarif") \
      -F checkout_uri="file://$(pwd)" \
      -F started_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")" || echo "SARIF upload failed, continuing..."
  else
    echo "GitHub environment variables missing, skipping SARIF upload"
  fi
  echo "::endgroup::"
else
  echo "⚠️ No SARIF files generated"
fi

# === Upload scan artifacts (ensure directory exists) ===
echo "::group::Upload artifacts"

# Copy SARIF files if they exist
if [ -d sarif-outputs ]; then
  find sarif-outputs -name "*.sarif" -type f -exec cp {} artifacts/ \; 2>/dev/null || true
  sarif_count=$(find sarif-outputs -name "*.sarif" -type f 2>/dev/null | wc -l)
  echo "Copied $sarif_count SARIF files to artifacts/"
else
  sarif_count=0
  echo "No sarif-outputs directory found"
fi

# Always create trivy-failures.txt in artifacts (even if empty)
if [ -f trivy-failures.txt ]; then
  cp trivy-failures.txt artifacts/
  echo "Copied trivy-failures.txt to artifacts/"
else
  touch artifacts/trivy-failures.txt
  echo "Created empty trivy-failures.txt in artifacts/"
fi

# Always create summary file
echo "Scanned repository: $REPO_NAME" > artifacts/scan-summary.txt
echo "Tags scanned: $sarif_count" >> artifacts/scan-summary.txt
echo "Scan date: $(date)" >> artifacts/scan-summary.txt
echo "Max tags limit: $MAX_TAGS" >> artifacts/scan-summary.txt
echo "Script completed successfully" >> artifacts/scan-summary.txt

# Create a README for troubleshooting
echo "Liquibase Docker Scan Results" > artifacts/README.md
echo "=============================" >> artifacts/README.md
echo "" >> artifacts/README.md
echo "Repository: $REPO_NAME" >> artifacts/README.md
echo "Scan Date: $(date)" >> artifacts/README.md
echo "SARIF Files: $sarif_count" >> artifacts/README.md
echo "" >> artifacts/README.md
if [ -s artifacts/trivy-failures.txt ]; then
  echo "⚠️ Vulnerable Tags Found:" >> artifacts/README.md
  echo "\`\`\`" >> artifacts/README.md
  cat artifacts/trivy-failures.txt >> artifacts/README.md
  echo "\`\`\`" >> artifacts/README.md
else
  echo "✅ No vulnerabilities found in scanned images!" >> artifacts/README.md
fi

# Verify artifacts directory content
echo "Artifacts directory contents:"
ls -la artifacts/ || echo "Failed to list artifacts directory"

echo "::endgroup::"

# === Print scan summary ===
if [[ -s trivy-failures.txt ]]; then
  echo "❌ The following tags had HIGH/CRITICAL vulnerabilities:"
  cat trivy-failures.txt
  exit 1
else
  echo "✅ No HIGH or CRITICAL vulnerabilities found."
fi