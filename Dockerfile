# Builder Stage
FROM eclipse-temurin:21-jre-noble

# Create liquibase user
RUN groupadd --gid 1001 liquibase && \
    useradd --uid 1001 --gid liquibase --create-home --home-dir /liquibase liquibase && \
    chown liquibase:root /liquibase && \
    chmod g+rx /liquibase

# Download and install Liquibase
WORKDIR /liquibase

ARG LIQUIBASE_VERSION=5.0.1
ARG LB_SHA256=3ae11ccdcd4c080e421e5fd043bdbd624d56fcfc9b294d5d9d898cb8b074e449

RUN wget -q -O liquibase-${LIQUIBASE_VERSION}.tar.gz "https://package.liquibase.com/downloads/dockerhub/official/liquibase-${LIQUIBASE_VERSION}.tar.gz" && \
    echo "$LB_SHA256 *liquibase-${LIQUIBASE_VERSION}.tar.gz" | sha256sum -c - && \
    tar -xzf liquibase-${LIQUIBASE_VERSION}.tar.gz && \
    rm liquibase-${LIQUIBASE_VERSION}.tar.gz && \
    ln -s /liquibase/liquibase /usr/local/bin/liquibase && \
    ln -s /liquibase/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh && \
    liquibase --version
    
ARG LPM_VERSION=0.2.17
ARG LPM_SHA256=f58e69ec338f5ab6abb60af5a03d9151bf17ae569662e54001963b61a5ac02d7
ARG LPM_SHA256_ARM=020a2ccd0d9a63b97de6109aee7558946f16fa55cdebb34218676c54c0cf7464
    
# Add metadata labels
LABEL org.opencontainers.image.description="Liquibase Container Image"
LABEL org.opencontainers.image.licenses="FSL-1.1-ALv2"
LABEL org.opencontainers.image.vendor="Liquibase"
LABEL org.opencontainers.image.version="${LIQUIBASE_VERSION}"
LABEL org.opencontainers.image.documentation="https://docs.liquibase.com"

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
