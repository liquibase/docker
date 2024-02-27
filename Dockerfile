# Builder Stage
FROM eclipse-temurin:17-jre-jammy

# Create liquibase user
RUN groupadd --gid 1001 liquibase && \
    useradd --uid 1001 --gid liquibase liquibase

# Install necessary dependencies
#RUN apt-get update && \
#    apt-get -yqq install krb5-user libpam-krb5 --no-install-recommends && \
#    rm -rf /var/lib/apt/lists/*

# Download and install Liquibase
WORKDIR /liquibase

ARG LIQUIBASE_VERSION=4.26.0
ARG LB_SHA256=46850b5fd21c548f969253cbbc97dc6c846198a8225581e3af5346ac8aa7dbf2

RUN wget -q -O liquibase-${LIQUIBASE_VERSION}.tar.gz "https://github.com/liquibase/liquibase/releases/download/v${LIQUIBASE_VERSION}/liquibase-${LIQUIBASE_VERSION}.tar.gz" && \
    echo "$LB_SHA256 *liquibase-${LIQUIBASE_VERSION}.tar.gz" | sha256sum -c - && \
    tar -xzf liquibase-${LIQUIBASE_VERSION}.tar.gz && \
    rm liquibase-${LIQUIBASE_VERSION}.tar.gz && \
    ln -s /liquibase/liquibase /usr/local/bin/liquibase && \
    ln -s /liquibase/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh && \
    liquibase --version

ARG LPM_VERSION=0.2.4
ARG LPM_SHA256=c3ecdc0fc0be75181b40e189289bf7fdb3fa62310a1d2cf768483b34e1d541cf
ARG LPM_SHA256_ARM=375acfa1e12aa0e11c4af65e231e6471ea8d5eea465fb58b516ea2ffbd18f3e0

# Download and Install lpm
RUN apt-get update && \
    apt-get -yqq install unzip --no-install-recommends && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir /liquibase/bin && \
    arch="$(dpkg --print-architecture)" && \
    case "$arch" in \
      amd64)  DOWNLOAD_ARCH=""  ;; \
      arm64)  DOWNLOAD_ARCH="-arm64" && LPM_SHA256=$LPM_SHA256_ARM ;; \
      *) echo >&2 "error: unsupported architecture '$arch'" && exit 1 ;; \
    esac && wget -q -O lpm-${LPM_VERSION}-linux${DOWNLOAD_ARCH}.zip "https://github.com/liquibase/liquibase-package-manager/releases/download/v${LPM_VERSION}/lpm-${LPM_VERSION}-linux${DOWNLOAD_ARCH}.zip" && \
    echo "$LPM_SHA256 *lpm-${LPM_VERSION}-linux${DOWNLOAD_ARCH}.zip" | sha256sum -c - && \
    unzip lpm-${LPM_VERSION}-linux${DOWNLOAD_ARCH}.zip -d bin/ && \
    rm lpm-${LPM_VERSION}-linux${DOWNLOAD_ARCH}.zip && \
    apt-get purge -y --auto-remove unzip && \
    ln -s /liquibase/bin/lpm /usr/local/bin/lpm && \
    lpm --version

# Set LIQUIBASE_HOME environment variable
ENV LIQUIBASE_HOME=/liquibase

COPY docker-entrypoint.sh ./
COPY liquibase.docker.properties ./

# Set user and group
USER liquibase:liquibase

ENTRYPOINT ["/liquibase/docker-entrypoint.sh"]
CMD ["--help"]
