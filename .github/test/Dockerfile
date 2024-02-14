FROM liquibase:test-entrypoint

USER root

ADD scripts /scripts
RUN chmod -R +x /scripts

USER liquibase

ENTRYPOINT ["/bin/bash"]

