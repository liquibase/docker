# Builder Stage
FROM eclipse-temurin:17-jre-jammy

# Create liquibase user
RUN groupadd --gid 1001 liquibase && \
    useradd --uid 1001 --gid liquibase --create-home --home-dir /liquibase liquibase && \
    chown liquibase /liquibase

# Install necessary dependencies
#RUN apt-get update && \
#    apt-get -yqq install krb5-user libpam-krb5 --no-install-recommends && \
#    rm -rf /var/lib/apt/lists/*

# Download and install Liquibase
WORKDIR /liquibase

ARG LIQUIBASE_VERSION=4.31.0
ARG LB_SHA256=ffcf80c34c8b05a50c32c423ad2899aa9e7a5cd40097628f2bc739b70654962d

RUN wget -q -O liquibase-${LIQUIBASE_VERSION}.tar.gz "https://github.com/liquibase/liquibase/releases/download/v${LIQUIBASE_VERSION}/liquibase-${LIQUIBASE_VERSION}.tar.gz" && \
    echo "$LB_SHA256 *liquibase-${LIQUIBASE_VERSION}.tar.gz" | sha256sum -c - && \
    tar -xzf liquibase-${LIQUIBASE_VERSION}.tar.gz && \
    rm liquibase-${LIQUIBASE_VERSION}.tar.gz && \
    ln -s /liquibase/liquibase /usr/local/bin/liquibase && \
    ln -s /liquibase/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh && \
    liquibase --version

ARG LPM_VERSION=0.2.9
ARG LPM_SHA256=FD45B897260810A3CC8C6D662FF7F4880AD11E2AB34F8965C5BD9CE223640C4B
ARG LPM_SHA256_ARM=A3C7ACEDB94ECBE2F5A7630966FC65D792265DB9B0EEACD23C58BB1FC0F6E4AA

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
# Marker which indicates this is a Liquibase docker container
ENV DOCKER_LIQUIBASE=true

COPY docker-entrypoint.sh ./
COPY liquibase.docker.properties ./

# Set user and group
USER liquibase:liquibase

ENTRYPOINT ["/liquibase/docker-entrypoint.sh"]
CMD ["--help"]
