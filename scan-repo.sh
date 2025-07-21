#!/bin/bash
set -euo pipefail

REPO_NAME="$1"
DOCKERHUB_NAMESPACE=liquibase

echo "🔍 Scanning all tags for $DOCKERHUB_NAMESPACE/$REPO_NAME..."

mkdir -p sarif-outputs
touch trivy-failures.txt

# Install dependencies
sudo apt-get update && sudo apt-get install -y jq curl
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
trivy --version

fetch_tags() {
  local url="https://hub.docker.com/v2/repositories/${DOCKERHUB_NAMESPACE}/${REPO_NAME}/tags?page_size=100"
  while [ -n "$url" ]; do
    echo "Fetching: $url"
    response=$(curl -s "$url")
    tags=$(echo "$response" | jq -r '.results[].name // empty')
    for tag in $tags; do
      echo "$tag"
    done
    url=$(echo "$response" | jq -r '.next')
    [ "$url" = "null" ] && break
  done
}

scan_tag() {
  local tag=$1
  local image="docker.io/${DOCKERHUB_NAMESPACE}/${REPO_NAME}:${tag}"
  local sarif="sarif-outputs/${REPO_NAME}--${tag//\//-}.sarif"

  echo "🧪 Scanning $image"
  if docker pull "$image"; then
    if ! trivy image \
      --vuln-type os,library \
      --scanners vuln \
      --format sarif \
      --output "$sarif" \
      --severity HIGH,CRITICAL \
      --exit-code 1 \
      "$image"; then
      echo "$image" >> trivy-failures.txt
    fi
  else
    echo "❌ Failed to pull $image"
  fi

  docker image rm "$image" || true
  docker system prune -f -a --volumes || true
}

for tag in $(fetch_tags); do
  if [[ "$tag" =~ ^[a-zA-Z0-9._-]+$ ]]; then
    scan_tag "$tag"
  else
    echo "⚠️ Skipping invalid tag: $tag"
  fi
done

echo "✅ Scanning complete for $REPO_NAME"

# === SARIF upload ===
echo "::group::Upload SARIF results"
gh api \
  --method POST \
  -H "Accept: application/vnd.github+json" \
  /repos/${GITHUB_REPOSITORY}/code-scanning/sarifs \
  -f commit_sha="${GITHUB_SHA}" \
  -f ref="${GITHUB_REF}" \
  -f sarif=@<(cat sarif-outputs/*.sarif | jq -s '{version: "2.1.0", runs: map(.runs[]) }') \
  -F checkout_uri="file://$(pwd)" \
  -F started_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo "::endgroup::"

# === Upload scan artifacts ===
echo "::group::Upload artifacts"
mkdir -p artifacts
cp -r sarif-outputs artifacts/
cp trivy-failures.txt artifacts/ || true
echo "::endgroup::"

# === Print scan summary ===
if [[ -s trivy-failures.txt ]]; then
  echo "❌ The following images had HIGH/CRITICAL vulnerabilities:"
  cat trivy-failures.txt
  exit 1
else
  echo "✅ No HIGH or CRITICAL vulnerabilities found."
fi
