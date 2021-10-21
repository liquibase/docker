FROM golang:1.16-buster as builder
ARG VERSION=3.0.1479.0
RUN set -ex && apt-get update && \
    apt-get install -y make git gcc libc-dev-bin curl bash && \
    go get golang.org/x/tools/cmd/goimports && \
    curl -sLO https://github.com/aws/amazon-ssm-agent/archive/${VERSION}.tar.gz && \
    mkdir -p /go/src/github.com && \
    tar xzf ${VERSION}.tar.gz && \
    mv amazon-ssm-agent-${VERSION} /go/src/github.com/amazon-ssm-agent && \
    cd /go/src/github.com/amazon-ssm-agent && \
    echo ${VERSION} > VERSION && \
    gofmt -w agent && make checkstyle || ./Tools/bin/goimports -w agent && \
    make build-linux


FROM openjdk:11-jre-slim-buster

# Install GNUPG for package vefification and WGET for file download
RUN apt-get update \
    && apt-get -yqq install krb5-user libpam-krb5 \
    && apt-get -y install gnupg wget unzip \
    && apt-get -y install sudo ca-certificates\
    && rm -rf /var/lib/apt/lists/*

# Add the liquibase user and step in the directory
RUN addgroup --gid 1001 liquibase
RUN adduser --disabled-password --uid 1001 --ingroup liquibase liquibase

# Add credentials and directories for AWS SSM agent
RUN adduser --disabled-password ssm-user \
    && echo "ssm-user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ssm-agent-users \
    && mkdir -p /etc/amazon/ssm

# Make /liquibase directory and change owner to liquibase
RUN mkdir /liquibase && chown liquibase /liquibase
WORKDIR /liquibase

#Symbolic link will be broken until later
RUN ln -s /liquibase/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh \
  && ln -s /liquibase/docker-entrypoint.sh /docker-entrypoint.sh \
  && ln -s /liquibase/liquibase /usr/local/bin/liquibase \
  && ln -s /liquibase/bin/lpm /usr/local/bin/lpm

# Change to the liquibase user
USER liquibase

# Latest Liquibase Release Version
ARG LIQUIBASE_VERSION=4.5.0

# Download, verify, extract
ARG LB_SHA256=4ce45bcbe4660b33eee93e80b9be968631e85566d02d90c0c5306fac8d4dd602
RUN set -x \
  && wget -O liquibase-${LIQUIBASE_VERSION}.tar.gz "https://github.com/liquibase/liquibase/releases/download/v${LIQUIBASE_VERSION}/liquibase-${LIQUIBASE_VERSION}.tar.gz" \
  && echo "$LB_SHA256  liquibase-${LIQUIBASE_VERSION}.tar.gz" | sha256sum -c - \
  && tar -xzf liquibase-${LIQUIBASE_VERSION}.tar.gz \
  && rm liquibase-${LIQUIBASE_VERSION}.tar.gz

# Download and Install lpm \
RUN mkdir /liquibase/bin
RUN wget -q -O lpm.zip https://github.com/liquibase/liquibase-package-manager/releases/download/v0.1.0/lpm-0.1.0-linux.zip
RUN unzip lpm.zip -d bin/
RUN rm lpm.zip
RUN export LIQUIBASE_HOME=/liquibase

# Install Drivers
RUN lpm add postgresql mssql mariadb db2 snowflake sybase firebird sqlite oracle --global
RUN ls -alh /liquibase/lib

COPY --chown=liquibase:liquibase docker-entrypoint.sh /liquibase/
COPY --chown=liquibase:liquibase liquibase.docker.properties /liquibase/

# Install AWS SSM agent
COPY --from=builder /go/src/github.com/amazon-ssm-agent/bin/linux_amd64/ /usr/bin
COPY --from=builder /go/src/github.com/amazon-ssm-agent/bin/amazon-ssm-agent.json.template /etc/amazon/ssm/amazon-ssm-agent.json
COPY --from=builder /go/src/github.com/amazon-ssm-agent/bin/seelog_unix.xml /etc/amazon/ssm/seelog.xml

VOLUME /liquibase/classpath
VOLUME /liquibase/changelog

ENTRYPOINT ["/liquibase/docker-entrypoint.sh"]
CMD ["--help"]
