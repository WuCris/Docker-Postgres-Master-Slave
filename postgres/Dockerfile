FROM postgres:16.1-alpine

COPY docker-entrypoint-initdb.d /docker-entrypoint-initdb.d
RUN chmod -R ug+x /docker-entrypoint-initdb.d