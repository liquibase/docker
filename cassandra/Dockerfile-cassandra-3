FROM cassandra:3

COPY test.cql /docker-entrypoint-initdb.d/test.cql

COPY cql.sh /cql.sh

ENTRYPOINT ["/cql.sh"]