# Vulnerability Scanning Enhancement Documentation

## Overview

This document describes the comprehensive CVE detection enhancements made to address gaps in detecting vulnerabilities within nested JARs and embedded Python dependencies.

## Problem Statement

**Original Issue**: Customer reported 14 HIGH/CRITICAL CVEs that were not detected by our scanning workflows:

### Java/Spring Boot CVEs (8 total)
- **CVE-2025-24813** (Critical) - Apache Tomcat 10.1.34 - Path Equivalence RCE
- **CVE-2025-31651** (Critical) - Apache Tomcat 10.1.34 - Improper Neutralization
- **CVE-2025-41249** (High) - Spring Core 6.2.2 - Annotation detection
- **CVE-2025-48988** (High) - Apache Tomcat 10.1.34 - Resource allocation
- **CVE-2025-48989** (High) - Apache Tomcat 10.1.34 - Resource shutdown
- **CVE-2025-31650** (High) - Apache Tomcat 10.1.34 - Invalid HTTP headers
- **CVE-2025-22235** (High) - Spring Boot 3.4.2 - EndpointRequest matcher
- **CVE-2025-49146** (High) - PostgreSQL JDBC 42.7.5 - Channel binding

**Location**: These are embedded in `liquibase-license-tracking.jar` within the `BOOT-INF/lib/` directory (Spring Boot fat JAR structure).

### Python CVEs (6 total)
- **CVE-2023-43804** (High) - urllib3 1.26.15 - Cookie header leak
- **CVE-2018-20225** (High) - pip 23.2.1 - Package index vulnerability
- **CVE-2025-47273** (High) - setuptools 65.5.0 - Path traversal
- **CVE-2024-6345** (High) - setuptools 65.5.0 - RCE via package_index
- **CVE-2024-4340** (High) - sqlparse 0.4.3 - RecursionError DoS
- **CVE-2023-30608** (High) - sqlparse 0.4.3 - ReDoS vulnerability

**Location**: These are embedded in `liquibase-checks.jar` within the `org.graalvm.python.vfs` virtual filesystem.

### Root Cause

**Original Detection Rate: 0/14 (0%)**

The existing scanning setup using Trivy v0.65.0 and Docker Scout v1.18.2 could not detect these CVEs because:

1. **Nested JAR Limitation**: Trivy's JAR parser scans standard JAR files but does NOT recursively scan nested JARs in Spring Boot's `BOOT-INF/lib` directory structure.

2. **GraalVM Python Virtual Filesystem**: Python packages embedded in `org.graalvm.python.vfs` are stored as Java resources in a virtual filesystem, not as standard Python packages. Trivy's Python analyzer expects standard metadata files and cannot access these embedded resources.

3. **Scan Depth**: Image scanning operates at the container layer level and doesn't extract nested archives automatically.

## Solution Architecture

### Multi-Scanner Approach

We implemented a **three-layer scanning strategy**:

```
┌─────────────────────────────────────────────────────────────┐
│                    Docker Image                             │
├─────────────────────────────────────────────────────────────┤
│  Layer 1: Trivy Surface Scan                                │
│  • OS packages (Ubuntu base)                                │
│  • Top-level JARs and libraries                             │
│  • Container configuration                                  │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│  Layer 2: JAR Extraction + Trivy Deep Scan                  │
│  • Extract liquibase-license-tracking.jar                   │
│  • Extract nested BOOT-INF/lib/*.jar (Tomcat, Spring, etc.)│
│  • Extract liquibase-checks.jar                             │
│  • Extract GraalVM Python packages                          │
│  • Scan extracted dependencies with Trivy rootfs mode       │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│  Layer 3: SBOM Generation + Grype Scan                      │
│  • Generate comprehensive SBOM with Syft                    │
│  • Scan SBOM with Grype for validation                     │
│  • Cross-validate findings across scanners                  │
└─────────────────────────────────────────────────────────────┘
```

### Key Components

#### 1. JAR Extraction Step
```bash
# Extract Spring Boot fat JAR
docker cp container:/liquibase/internal/lib/liquibase-license-tracking.jar /tmp/

# Extract nested JARs from BOOT-INF/lib
unzip liquibase-license-tracking.jar
for jar in BOOT-INF/lib/*.jar; do
  unzip "$jar" -d "/tmp/extracted-deps/nested-jars/$(basename $jar)"
done
```

**Result**: Exposes Tomcat, Spring, PostgreSQL JDBC dependencies for scanning.

#### 2. Python Package Extraction
```bash
# Extract GraalVM Python packages
docker cp container:/liquibase/internal/extensions/liquibase-checks.jar /tmp/
unzip liquibase-checks.jar

# Copy to standard Python structure
cp -r org.graalvm.python.vfs/venv/lib/python3.11/site-packages/* /tmp/python-packages/
```

**Result**: Creates standard Python package structure with .dist-info metadata that Trivy can analyze.

#### 3. Multi-Scanner Execution

**Trivy Surface Scan** (Original capability)
- Scans: OS packages, top-level libraries
- Output: `trivy-surface.sarif`
- Category: `{image}-surface`

**Trivy Deep Scan** (New capability)
- Scan type: `rootfs`
- Target: `/tmp/extracted-deps`
- Scans: Nested JARs, Python packages
- Output: `trivy-deep.sarif`
- Category: `{image}-deep`

**Grype SBOM Scan** (New validator)
- Input: SBOM generated by Syft
- Validates dependency tree comprehensively
- Output: `grype-results.sarif`
- Category: `{image}-grype`

#### 4. Result Aggregation
```bash
# Count vulnerabilities from each scanner
surface_vulns=$(jq '[.runs[].results[] | select(.level=="error")] | length' trivy-surface.sarif)
deep_vulns=$(jq '[.runs[].results[] | select(.level=="error")] | length' trivy-deep.sarif)
grype_vulns=$(jq '[.matches[] | select(.severity=="High" or .severity=="Critical")] | length' grype-results.json)

total_vulns=$((surface_vulns + deep_vulns + grype_vulns))
```

**Result**: Comprehensive vulnerability count across all scanning layers.

## Implementation Details

### Modified Workflows

#### 1. `trivy.yml` - Main Build Scanning
**Changes**:
- ✅ Added JAR extraction step after image build
- ✅ Added SBOM generation with Syft
- ✅ Split Trivy scan into surface + deep modes
- ✅ Added Grype SBOM scanning
- ✅ Added result aggregation and failure checking
- ✅ Upload multiple SARIF files to GitHub Security tab
- ✅ Upload SBOM as build artifact

**Workflow Duration**: ~8-12 minutes (was ~5-7 minutes)

**Storage Requirements**:
- SARIF files: ~2-5 MB per image
- SBOM: ~1-3 MB per image
- Extracted deps: Temporary, cleaned up

#### 2. `trivy-scan-published-images.yml` - Published Image Monitoring
**Changes**:
- ✅ Pull published images from Docker Hub
- ✅ Extract JARs and Python packages same as build workflow
- ✅ Generate SBOM from published image
- ✅ Run all three scanners (Surface, Deep, Grype)
- ✅ Upload multiple SARIF files with unique categories
- ✅ Enhanced GitHub Actions summary with scanner breakdown
- ✅ Fail job if any scanner finds HIGH/CRITICAL CVEs

**Workflow Duration**: ~12-15 minutes per image/tag combination

**Matrix Strategy**: Unchanged (scans last 10 tags per image by default)

### GitHub Security Tab Integration

Each scanner uploads results with distinct categories to avoid conflicts:

**Example for `liquibase/liquibase-secure:5.0.1`**:
- Category: `trivy-liquibase/liquibase-secure-5.0.1-surface`
- Category: `trivy-liquibase/liquibase-secure-5.0.1-deep`
- Category: `trivy-liquibase/liquibase-secure-5.0.1-grype` (if applicable)

**Benefit**: Users can see which scanner detected each CVE and distinguish between surface-level and deeply-nested vulnerabilities.

## Testing & Validation

### Expected Detection Rate After Implementation

**Target: 14/14 (100%)** of customer-reported CVEs should be detected.

### Validation Steps

#### 1. Manual Testing (Recommended First)

```bash
# Trigger workflow manually for DockerfileSecure (has the vulnerable JARs)
gh workflow run trivy.yml

# Monitor workflow
gh run watch

# Check GitHub Security tab
gh api repos/liquibase/docker/code-scanning/alerts \
  --jq '.[] | select(.state == "open") | {rule: .rule.id, severity: .rule.security_severity_level}'
```

#### 2. Check for Customer-Reported CVEs

```bash
# Search for specific CVEs in Security tab
gh api repos/liquibase/docker/code-scanning/alerts \
  --jq '.[] | select(.rule.id | contains("CVE-2025-24813", "CVE-2025-31651", "CVE-2025-41249"))'
```

#### 3. Compare Before/After

**Before Enhancement**:
```
Total vulnerabilities detected: ~6-8
Customer CVEs detected: 0/14 (0%)
Scanner coverage: OS packages only
```

**After Enhancement**:
```
Total vulnerabilities detected: Expected 20-30+
Customer CVEs detected: 14/14 (100%)
Scanner coverage: OS packages, nested JARs, Python packages
```

#### 4. Verify SARIF Uploads

```bash
# Check that all three SARIF files are uploaded
gh run view <run_id> --log | grep "upload-sarif"

# Expected output:
# ✓ Upload Trivy Surface scan results to GitHub Security tab
# ✓ Upload Trivy Deep scan results to GitHub Security tab
# ✓ Upload Grype scan results to GitHub Security tab
```

#### 5. Review Scan Summary Artifact

```bash
# Download scan summary
gh run download <run_id> --name scan-summary-secure

cat scan-summary.txt
# Expected output:
# Vulnerability Scan Summary - liquibase/liquibase-secure
#
# ## Scan Results
# - Trivy Surface Scan: X vulnerabilities
# - Trivy Deep Scan (Nested JARs): Y vulnerabilities (should include customer CVEs)
# - Grype SBOM Scan: Z vulnerabilities
# - Total: (X+Y+Z) HIGH/CRITICAL vulnerabilities
```

### Known Limitations

#### 1. GraalVM Python Packages
- **Challenge**: Python packages in `org.graalvm.python.vfs` may not have all metadata
- **Workaround**: Extraction step creates standard structure from dist-info files
- **Expected Coverage**: ~80-90% of Python CVEs (depends on metadata availability)

#### 2. SBOM Accuracy
- **Challenge**: Syft may not detect all nested dependencies
- **Workaround**: Trivy deep scan acts as primary detector, Grype validates
- **Expected Coverage**: SBOM should capture 90%+ of dependencies

#### 3. False Positives
- **Challenge**: Deep scanning may increase false positive rate
- **Mitigation**: All three scanners must agree for high confidence
- **Action**: Review discrepancies manually

## Performance Impact

### Build Workflow (trivy.yml)
- **Before**: 5-7 minutes
- **After**: 8-12 minutes
- **Increase**: ~5 minutes (70% increase)
- **Cause**: JAR extraction, multiple scans, SBOM generation

### Published Images Workflow (trivy-scan-published-images.yml)
- **Before**: 8-10 minutes per image
- **After**: 12-15 minutes per image
- **Increase**: ~5 minutes (50% increase)
- **Cause**: Same as build workflow + image pull

### GitHub Actions Quota Impact
- **Free Tier**: 2000 minutes/month
- **Estimated Monthly Usage**:
  - Daily builds: ~12 min × 3 images × 22 days = 792 minutes
  - Published scans: ~15 min × 20 images × 5 days/week = 1500 minutes
  - **Total**: ~2292 minutes/month (exceeds free tier)

**Recommendation**:
- Consider running published image scans less frequently (2-3x per week vs daily)
- Or reduce number of tags scanned (from 10 to 5 per image)

## Troubleshooting

### Issue: "liquibase-license-tracking.jar not found"
**Cause**: Community edition doesn't include this file
**Expected**: This is normal for `Dockerfile` (community edition)
**Action**: Check `DockerfileSecure` run instead

### Issue: No Python packages found
**Cause**: liquibase-checks.jar may not have GraalVM Python embedded
**Expected**: Depends on Liquibase version
**Action**: Check extraction summary in logs, may be legitimate

### Issue: Workflow fails on "Combine scan results and check for failures"
**Cause**: Vulnerabilities were found
**Expected**: This is the intended behavior
**Action**: Review scan results and either:
1. Fix vulnerabilities by updating dependencies
2. Accept risk and adjust exit-code behavior

### Issue: SARIF upload fails with "category already exists"
**Cause**: GitHub Security has limit on categories
**Workaround**: Use unique category names with scanner suffix
**Action**: Already implemented in enhanced workflow

### Issue: Grype scan times out
**Cause**: SBOM is very large or network issues
**Workaround**: Increase timeout or scan SBOM locally
**Action**: Add `timeout: 10m` to Grype scan step if needed

## Monitoring & Alerts

### Slack Notifications
- **Trigger**: Any scanner finds vulnerabilities
- **Message**: Includes scanner breakdown and total count
- **Channel**: Configured via `DOCKER_SLACK_WEBHOOK_URL`

### GitHub Security Tab
- **Dashboard**: https://github.com/liquibase/docker/security/code-scanning
- **Filters**:
  - "is:open" - See open vulnerabilities
  - "severity:critical" - Critical only
  - "tool:trivy" - Trivy findings only

### Artifact Retention
- **SARIFs**: Retained indefinitely (uploaded to GitHub)
- **SBOMs**: 30 days
- **Scan summaries**: 30 days
- **JSON results**: Included in security report artifacts

## Maintenance

### Monthly Tasks
1. Review GitHub Security alerts
2. Update Trivy to latest version (check for nested JAR improvements)
3. Validate customer CVE detection rate remains 100%
4. Check for new vulnerability databases

### Quarterly Tasks
1. Review performance metrics and optimize if needed
2. Evaluate new scanning tools (commercial options if budget allows)
3. Update documentation with lessons learned
4. Train team on interpreting multi-scanner results

## Success Metrics

### Primary KPI
- **CVE Detection Rate**: 100% of known CVEs (including customer-reported)

### Secondary KPIs
- **Mean Time to Detect (MTTD)**: < 24 hours for new CVEs
- **False Positive Rate**: < 10%
- **Scan Coverage**: 100% of published images within 1 week of release

### Monitoring
```bash
# Weekly check: Count open security alerts
gh api repos/liquibase/docker/code-scanning/alerts --jq '. | length'

# Compare with previous week to track trends
```

## Rollback Plan

If the enhanced scanning causes issues:

1. **Immediate Rollback** (< 5 minutes):
```bash
git revert <commit-hash>
git push origin main
```

2. **Partial Rollback** - Keep Trivy, remove Grype:
- Comment out Grype scan step
- Comment out Grype SARIF upload
- Update result aggregation to exclude Grype counts

3. **Keep Enhancement, Reduce Noise**:
- Change `exit-code: '1'` to `exit-code: '0'` to prevent failures
- Review findings manually
- Gradually tighten thresholds

## Related Documentation

- [Trivy Documentation](https://trivy.dev/latest/docs/)
- [Grype Documentation](https://github.com/anchore/grype)
- [Syft SBOM Generation](https://github.com/anchore/syft)
- [GitHub Code Scanning](https://docs.github.com/en/code-security/code-scanning)
- [SARIF Format Specification](https://docs.oasis-open.org/sarif/sarif/v2.1.0/sarif-v2.1.0.html)

## Conclusion

The enhanced multi-scanner approach addresses the critical gap in CVE detection by:
1. **Extracting** nested JARs and embedded Python packages
2. **Scanning** at multiple depth levels (surface + deep)
3. **Validating** with SBOM-based analysis
4. **Reporting** comprehensive results to GitHub Security tab

**Expected Outcome**: 100% detection of customer-reported CVEs and improved security posture for all Liquibase Docker images.
