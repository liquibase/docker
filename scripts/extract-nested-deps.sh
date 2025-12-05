#!/usr/bin/env bash
#
# extract-nested-deps.sh
#
# Extracts nested JARs and Python packages from Liquibase Docker images for deep vulnerability scanning.
# This script handles Spring Boot nested JARs (BOOT-INF/lib) and GraalVM Python packages.
#
# Usage:
#   extract-nested-deps.sh <image_ref>
#
# Arguments:
#   image_ref: Docker image reference (e.g., liquibase/liquibase:latest or image:sha)
#
# Environment Variables:
#   EXTRACT_DIR: Base directory for extraction (default: /tmp/extracted-deps)
#
# Outputs:
#   - Extracted JAR files in ${EXTRACT_DIR}/internal-jars/{lib,extensions}
#   - Nested JARs from archives in ${EXTRACT_DIR}/dist/
#   - Python packages in ${EXTRACT_DIR}/python-packages
#   - JAR mapping file in ${EXTRACT_DIR}/jar-mapping.txt

set -e

# Configuration
IMAGE_REF="${1:?Error: Image reference required}"
EXTRACT_DIR="${EXTRACT_DIR:-/tmp/extracted-deps}"

echo "📦 Extracting nested dependencies from ${IMAGE_REF}..."

# Create extraction directory
mkdir -p "${EXTRACT_DIR}"

# Create container from image to extract files
container_id=$(docker create "${IMAGE_REF}")
trap "docker rm ${container_id} > /dev/null 2>&1" EXIT

echo "🔍 Extracting all JAR files from container..."

# Extract distribution archives if they exist
echo "🔍 Checking /liquibase/dist for tar.gz archives..."
if docker cp "${container_id}:/liquibase/dist" /tmp/liquibase-dist 2>/dev/null; then
  echo "✓ Found /liquibase/dist directory"

  # Extract all tar.gz archives
  find /tmp/liquibase-dist -name "*.tar.gz" -type f | while read -r archive; do
    archive_name=$(basename "$archive" .tar.gz)
    echo "  📦 Extracting $archive_name..."
    extract_dir="/tmp/liquibase-dist/${archive_name}-extracted"
    mkdir -p "$extract_dir"
    tar -xzf "$archive" -C "$extract_dir" 2>/dev/null || true

    # Find JARs in extracted archive
    jar_count=$(find "$extract_dir" -name "*.jar" -type f | wc -l)
    if [ "$jar_count" -gt 0 ]; then
      echo "  ✓ Found $jar_count JAR(s) in $archive_name"

      # Extract each JAR from the archive
      find "$extract_dir" -name "*.jar" -type f | while read -r jar_file; do
        jar_name=$(basename "$jar_file" .jar)
        jar_extract="${EXTRACT_DIR}/dist/${archive_name}/${jar_name}"
        mkdir -p "$jar_extract"
        unzip -q "$jar_file" -d "$jar_extract" 2>/dev/null || true

        # Check for Spring Boot nested JARs and copy them as-is (don't extract)
        if [ -d "$jar_extract/BOOT-INF/lib" ]; then
          echo "    ✓ Spring Boot JAR: $jar_name - preserving nested JAR files"
          nested_count=0
          nested_jar_dir="${EXTRACT_DIR}/dist/${archive_name}/${jar_name}-nested-jars"
          mkdir -p "$nested_jar_dir"

          # Create a mapping file to track parent JAR relationships
          mapping_file="${EXTRACT_DIR}/jar-mapping.txt"

          for nested_jar in "$jar_extract/BOOT-INF/lib"/*.jar; do
            if [ -f "$nested_jar" ]; then
              nested_count=$((nested_count + 1))
              nested_jar_name=$(basename "$nested_jar")

              # Copy the JAR file as-is, don't extract it
              cp "$nested_jar" "$nested_jar_dir/" 2>/dev/null || true

              # Record the parent → nested relationship
              echo "${jar_name}.jar|$nested_jar_name" >> "$mapping_file"
            fi
          done
          echo "      → Preserved $nested_count nested JAR file(s)"
        fi
      done
    fi
  done
else
  echo "⚠ No /liquibase/dist directory found"
fi

# Copy entire internal directory for comprehensive scanning
if docker cp "${container_id}:/liquibase/internal" /tmp/liquibase-internal 2>/dev/null; then
  echo "✓ Copied /liquibase/internal directory"

  # Count total JARs
  jar_count=$(find /tmp/liquibase-internal -name "*.jar" -type f | wc -l)
  echo "📊 Found $jar_count JAR files to scan"

  # Copy all JAR files preserving them for Trivy to scan
  mkdir -p "${EXTRACT_DIR}/internal-jars/lib"
  mkdir -p "${EXTRACT_DIR}/internal-jars/extensions"

  # Copy lib JARs as-is
  if [ -d /tmp/liquibase-internal/lib ]; then
    cp /tmp/liquibase-internal/lib/*.jar "${EXTRACT_DIR}/internal-jars/lib/" 2>/dev/null || true
    lib_jar_count=$(ls -1 "${EXTRACT_DIR}/internal-jars/lib/"*.jar 2>/dev/null | wc -l)
    echo "  ✓ Preserved $lib_jar_count lib JAR(s)"
  fi

  # Copy extension JARs as-is
  if [ -d /tmp/liquibase-internal/extensions ]; then
    cp /tmp/liquibase-internal/extensions/*.jar "${EXTRACT_DIR}/internal-jars/extensions/" 2>/dev/null || true
    ext_jar_count=$(ls -1 "${EXTRACT_DIR}/internal-jars/extensions/"*.jar 2>/dev/null | wc -l)
    echo "  ✓ Preserved $ext_jar_count extension JAR(s)"
  fi

  echo "✓ Preserved $jar_count JAR files for scanning"
else
  echo "⚠ Could not copy /liquibase/internal directory"
fi

# Extract all extension JARs and look for GraalVM Python embedded dependencies
echo "🔍 Scanning extension JARs for Python packages..."
mkdir -p "${EXTRACT_DIR}/python-packages"

# Scan all JARs in internal-jars/extensions directory
if [ -d "${EXTRACT_DIR}/internal-jars/extensions" ]; then
  for ext_jar in "${EXTRACT_DIR}/internal-jars/extensions"/*.jar; do
    if [ -f "$ext_jar" ]; then
      jar_name=$(basename "$ext_jar")
      jar_extract="${EXTRACT_DIR}/extension-scan/${jar_name%.jar}"
      mkdir -p "$jar_extract"
      unzip -q "$ext_jar" -d "$jar_extract" 2>/dev/null || true

      # Check if this JAR contains GraalVM Python packages
      if [ -d "$jar_extract/org.graalvm.python.vfs" ]; then
        echo "  ✓ Found Python packages in $jar_name"

        # Copy from both possible locations
        if [ -d "$jar_extract/org.graalvm.python.vfs/venv/lib/python3.11/site-packages" ]; then
          cp -r "$jar_extract/org.graalvm.python.vfs/venv/lib/python3.11/site-packages"/* "${EXTRACT_DIR}/python-packages/" 2>/dev/null || true
        fi
        if [ -d "$jar_extract/org.graalvm.python.vfs/venv/Lib/site-packages" ]; then
          cp -r "$jar_extract/org.graalvm.python.vfs/venv/Lib/site-packages"/* "${EXTRACT_DIR}/python-packages/" 2>/dev/null || true
        fi

        # Also extract bundled wheels
        if [ -d "$jar_extract/META-INF/resources/libpython/ensurepip/_bundled" ]; then
          mkdir -p "${EXTRACT_DIR}/python-bundled"
          cp "$jar_extract/META-INF/resources/libpython/ensurepip/_bundled"/*.whl "${EXTRACT_DIR}/python-bundled/" 2>/dev/null || true
        fi
      fi
    fi
  done
fi

# Save manifest of JAR files for reporting
echo "📝 Creating JAR manifest..."
MANIFEST="${EXTRACT_DIR}/scanned-jars.txt"
{
  # List lib JARs
  if [ -d "${EXTRACT_DIR}/internal-jars/lib" ]; then
    ls -1 "${EXTRACT_DIR}/internal-jars/lib/"*.jar 2>/dev/null | xargs -n1 basename 2>/dev/null || true
  fi
  # List extension JARs
  if [ -d "${EXTRACT_DIR}/internal-jars/extensions" ]; then
    ls -1 "${EXTRACT_DIR}/internal-jars/extensions/"*.jar 2>/dev/null | xargs -n1 basename 2>/dev/null || true
  fi
  # List nested JARs from dist archives
  if [ -d "${EXTRACT_DIR}/dist" ]; then
    find "${EXTRACT_DIR}/dist" -type d -name "*-nested-jars" -exec ls -1 {} \; 2>/dev/null | xargs -n1 basename 2>/dev/null || true
  fi
} | sort -u > "$MANIFEST"
manifest_count=$(wc -l < "$MANIFEST" | tr -d ' ')
echo "✓ Created manifest with ${manifest_count} JAR files"

# Show what was extracted
echo ""
echo "📊 Extraction Summary:"
total_files=$(find "${EXTRACT_DIR}" -type f 2>/dev/null | wc -l)
echo "Total files extracted: $total_files"

if [ -d "${EXTRACT_DIR}/dist" ]; then
  dist_archives=$(find /tmp/liquibase-dist -name "*.tar.gz" -type f 2>/dev/null | wc -l)
  dist_jars=$(find /tmp/liquibase-dist -name "*.jar" -type f 2>/dev/null | wc -l)
  nested_jars=$(find "${EXTRACT_DIR}/dist" -type d -name "*-nested-jars" -exec sh -c 'ls -1 "{}"/*.jar 2>/dev/null | wc -l' \; 2>/dev/null | awk '{s+=$1} END {print s}')
  echo "Distribution archives: $dist_archives"
  echo "  - JARs in archives: $dist_jars"
  if [ "$nested_jars" -gt 0 ]; then
    echo "  - Spring Boot nested JARs: $nested_jars"
  fi
fi

if [ -d "${EXTRACT_DIR}/internal-jars" ]; then
  lib_jars=$(ls -1 "${EXTRACT_DIR}/internal-jars/lib/"*.jar 2>/dev/null | wc -l)
  ext_jars=$(ls -1 "${EXTRACT_DIR}/internal-jars/extensions/"*.jar 2>/dev/null | wc -l)
  total_internal=$((lib_jars + ext_jars))
  echo "Internal JARs preserved: $total_internal"
  echo "  - Lib JARs: $lib_jars"
  echo "  - Extension JARs: $ext_jars"
fi

if [ -d "${EXTRACT_DIR}/python-packages" ]; then
  python_pkgs=$(ls -1 "${EXTRACT_DIR}/python-packages" 2>/dev/null | grep -E '\.(dist-info|egg-info)$' | wc -l)
  echo "Python packages found: $python_pkgs"
fi

echo "✅ Extraction complete"
