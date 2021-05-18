FROM liquibase/liquibase

ARG SNOWFLAKE_EXTENSION_SHA1=afd8b4aa546294589d50e2ad2c5ccf891e601479
RUN wget --no-verbose -O /liquibase/lib/snowflake-extension.jar https://repo1.maven.org/maven2/org/liquibase/ext/liquibase-snowflake/4.3.5/liquibase-snowflake-4.3.5.jar \
	&& wget --no-verbose -O wget -O /liquibase/lib/snowflake-extension.jar.asc https://repo1.maven.org/maven2/org/liquibase/ext/liquibase-snowflake/4.3.5/liquibase-snowflake-4.3.5.jar.asc \
    && gpg --auto-key-locate keyserver --keyserver ha.pool.sks-keyservers.net --keyserver-options auto-key-retrieve --verify /liquibase/lib/snowflake-extension.jar.asc /liquibase/lib/snowflake-extension.jar \
	&& echo "$SNOWFLAKE_EXTENSION_SHA1 /liquibase/lib/snowflake-extension.jar" | sha1sum -c -


