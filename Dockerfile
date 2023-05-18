FROM eclipse-temurin:17-jre-jammy

ARG TARGETARCH

# Install GNUPG for package verification and WGET for file download
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get -yqq install krb5-user libpam-krb5 --no-install-recommends && \
    apt-get -y install gnupg wget unzip --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# Add the liquibase user and step in the directory
RUN addgroup --gid 1001 liquibase && \
    adduser --disabled-password --uid 1001 --ingroup liquibase liquibase

# Make /liquibase directory and change owner to liquibase
RUN mkdir /liquibase && chown liquibase /liquibase
WORKDIR /liquibase

# Symbolic link will be broken until later
RUN ln -s /liquibase/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh && \
    ln -s /liquibase/docker-entrypoint.sh /docker-entrypoint.sh && \
    ln -s /liquibase/liquibase /usr/local/bin/liquibase && \
    ln -s /liquibase/bin/lpm /usr/local/bin/lpm

# Change to the liquibase user
USER liquibase

# Set LIQUIBASE_HOME environment variable
ENV LIQUIBASE_HOME=/liquibase

# Latest Liquibase Release Version
ARG LIQUIBASE_VERSION=4.22.0
ARG LPM_VERSION=0.2.2

# Download, verify, extract
ARG LB_SHA256=caa019320608313709593762409a70943f9678fcc8e1ba19b5b84927f53de457
RUN set -x && \
    wget -q -O liquibase-${LIQUIBASE_VERSION}.tar.gz "https://github.com/liquibase/liquibase/releases/download/v${LIQUIBASE_VERSION}/liquibase-${LIQUIBASE_VERSION}.tar.gz" && \
    echo "$LB_SHA256  liquibase-${LIQUIBASE_VERSION}.tar.gz" | sha256sum -c - && \
    tar -xzf liquibase-${LIQUIBASE_VERSION}.tar.gz && \
    rm liquibase-${LIQUIBASE_VERSION}.tar.gz

# Download and Install lpm
RUN mkdir /liquibase/bin && \
    case ${TARGETARCH} in \
      "amd64")  DOWNLOAD_ARCH=""  ;; \
      "arm64")  DOWNLOAD_ARCH="-arm64"  ;; \
    esac &&  wget -v -O lpm.zip "https://github.com/liquibase/liquibase-package-manager/releases/download/v${LPM_VERSION}/lpm-${LPM_VERSION}-linux${DOWNLOAD_ARCH}.zip" && \
    unzip lpm.zip -d bin/ && \
    rm lpm.zip

# Install Drivers
RUN lpm update && \
    /liquibase/liquibase --version

COPY --chown=liquibase:liquibase docker-entrypoint.sh /liquibase/
COPY --chown=liquibase:liquibase liquibase.docker.properties /liquibase/

## This is not used for anything beyond an alternative location for "/liquibase/changelog", but remains for backwards compatibility
VOLUME /liquibase/classpath

VOLUME /liquibase/changelog
VOLUME /liquibase/lib

ENTRYPOINT ["/liquibase/docker-entrypoint.sh"]
CMD ["--help"]
