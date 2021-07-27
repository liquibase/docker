FROM liquibase/liquibase

ARG SNOWFLAKE_EXTENSION_VERSION=4.4.2
ARG SNOWFLAKE_EXTENSION_SHA1=3e721e766a42fa8b3b80982e05f8bf08d5af24d8
RUN wget --no-verbose -O /liquibase/lib/snowflake-extension.jar https://repo1.maven.org/maven2/org/liquibase/ext/liquibase-snowflake/${SNOWFLAKE_EXTENSION_VERSION}/liquibase-snowflake-${SNOWFLAKE_EXTENSION_VERSION}.jar \
	&& wget --no-verbose -O wget -O /liquibase/lib/snowflake-extension.jar.asc https://repo1.maven.org/maven2/org/liquibase/ext/liquibase-snowflake/${SNOWFLAKE_EXTENSION_VERSION}/liquibase-snowflake-${SNOWFLAKE_EXTENSION_VERSION}.jar.asc \
    && gpg --auto-key-locate keyserver --keyserver keyserver.ubuntu.com --keyserver-options auto-key-retrieve --verify /liquibase/lib/snowflake-extension.jar.asc /liquibase/lib/snowflake-extension.jar \
	&& echo "$SNOWFLAKE_EXTENSION_SHA1 /liquibase/lib/snowflake-extension.jar" | sha1sum -c -


