# Builder Stage
FROM eclipse-temurin:21-jre-jammy

# Create liquibase user
RUN groupadd --gid 1001 liquibase \
 && useradd --uid 1001 --gid liquibase --create-home --home-dir /liquibase liquibase \
 && chown liquibase:liquibase /liquibase

WORKDIR /liquibase

ARG LIQUIBASE_VERSION=4.33.0
ARG LB_SHA256=689acfcdc97bad0d4c150d1efab9c851e251b398cb3d6326f75e8aafe40ed578

# --- install Liquibase as root (default) ---
RUN wget -q -O liquibase-${LIQUIBASE_VERSION}.tar.gz "https://package.liquibase.com/downloads/dockerhub/official/liquibase-${LIQUIBASE_VERSION}.tar.gz" \
 && echo "$LB_SHA256 *liquibase-${LIQUIBASE_VERSION}.tar.gz" | sha256sum -c - \
 && tar -xzf liquibase-${LIQUIBASE_VERSION}.tar.gz \
 && rm liquibase-${LIQUIBASE_VERSION}.tar.gz \
 && ln -s /liquibase/liquibase /usr/local/bin/liquibase \
 && ln -s /liquibase/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh \
 && liquibase --version

ARG LPM_VERSION=0.2.12
ARG LPM_SHA256=93748cc512761fd0a77cdf556b02519b7d9ab47f3b547aa394b6e3a02576c5d2
ARG LPM_SHA256_ARM=d891808746cbc0f86b396b95823519d430759006386b2f13973dbd60829e8b86

LABEL org.opencontainers.image.description="Liquibase Container Image"
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL org.opencontainers.image.vendor="Liquibase"
LABEL org.opencontainers.image.version="${LIQUIBASE_VERSION}"
LABEL org.opencontainers.image.documentation="https://docs.liquibase.com"

# Install lpm
RUN apt-get update \
 && apt-get -yqq install unzip --no-install-recommends \
 && rm -rf /var/lib/apt/lists/* \
 && mkdir /liquibase/bin \
 && arch="$(dpkg --print-architecture)" \
 && case "$arch" in \
      amd64)  DOWNLOAD_ARCH="" ;; \
      arm64)  DOWNLOAD_ARCH="-arm64"; LPM_SHA256="$LPM_SHA256_ARM" ;; \
      *) echo >&2 "error: unsupported architecture '$arch'"; exit 1 ;; \
    esac \
 && wget -q -O "lpm-${LPM_VERSION}-linux${DOWNLOAD_ARCH}.zip" "https://github.com/liquibase/liquibase-package-manager/releases/download/v${LPM_VERSION}/lpm-${LPM_VERSION}-linux${DOWNLOAD_ARCH}.zip" \
 && echo "$LPM_SHA256 *lpm-${LPM_VERSION}-linux${DOWNLOAD_ARCH}.zip" | sha256sum -c - \
 && unzip "lpm-${LPM_VERSION}-linux${DOWNLOAD_ARCH}.zip" -d bin/ \
 && rm "lpm-${LPM_VERSION}-linux${DOWNLOAD_ARCH}.zip" \
 && apt-get purge -y --auto-remove unzip \
 && ln -s /liquibase/bin/lpm /usr/local/bin/lpm \
 && lpm --version

# ── NEW: create a separate, writable Liquibase HOME for the non-root user ──
# This is where lpm will write packages.json and drivers.
RUN install -d -o liquibase -g liquibase /opt/liquibase-home/lib

# Set LIQUIBASE_HOME to the user-owned path
ENV LIQUIBASE_HOME=/opt/liquibase-home
ENV DOCKER_LIQUIBASE=true

COPY docker-entrypoint.sh ./
COPY liquibase.docker.properties ./

# Drop to non-root
USER liquibase:liquibase

ENTRYPOINT ["/liquibase/docker-entrypoint.sh"]
CMD ["--help"]
