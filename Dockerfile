# Builder Stage
FROM eclipse-temurin:17-jre-jammy as builder

ARG TARGETARCH
ARG LIQUIBASE_VERSION=4.25.1
ARG LPM_VERSION=0.2.4
ARG LB_SHA256=8b2b7aa8ec755d4ee52fa0210cd2a244fd16ed695fc4a72245562950776d2a56

# Install necessary dependencies
RUN apt-get update && \
    apt-get -yqq install krb5-user libpam-krb5 gnupg wget unzip --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# Download and install Liquibase
WORKDIR /liquibase
RUN wget -q -O liquibase-${LIQUIBASE_VERSION}.tar.gz "https://github.com/liquibase/liquibase/releases/download/v${LIQUIBASE_VERSION}/liquibase-${LIQUIBASE_VERSION}.tar.gz" && \
    echo "$LB_SHA256  liquibase-${LIQUIBASE_VERSION}.tar.gz" | sha256sum -c - && \
    tar -xzf liquibase-${LIQUIBASE_VERSION}.tar.gz && \
    rm liquibase-${LIQUIBASE_VERSION}.tar.gz

# Download and Install lpm
RUN mkdir bin && \
    case ${TARGETARCH} in \
      "amd64")  DOWNLOAD_ARCH=""  ;; \
      "arm64")  DOWNLOAD_ARCH="-arm64"  ;; \
    esac &&  wget -v -O lpm.zip "https://github.com/liquibase/liquibase-package-manager/releases/download/v${LPM_VERSION}/lpm-${LPM_VERSION}-linux${DOWNLOAD_ARCH}.zip" && \
    unzip lpm.zip -d bin/ && \
    rm lpm.zip
    
# Production Stage
FROM eclipse-temurin:17-jre-jammy as production

# Create liquibase user
RUN addgroup --gid 1001 liquibase && \
    adduser --disabled-password --uid 1001 --ingroup liquibase liquibase && \
    mkdir /liquibase && chown root:root /liquibase

# Setup symbolic links
RUN ln -s /liquibase/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh && \
    ln -s /liquibase/docker-entrypoint.sh /docker-entrypoint.sh && \
    ln -s /liquibase/liquibase /usr/local/bin/liquibase && \
    ln -s /liquibase/bin/lpm /usr/local/bin/lpm

WORKDIR /liquibase
USER liquibase
ENV LIQUIBASE_HOME=/liquibase

# Copy from builder stage
COPY --from=builder /liquibase /liquibase

COPY --chown=liquibase:liquibase docker-entrypoint.sh /liquibase/
COPY --chown=liquibase:liquibase liquibase.docker.properties /liquibase/

ENTRYPOINT ["/liquibase/docker-entrypoint.sh"]
CMD ["--help"]
