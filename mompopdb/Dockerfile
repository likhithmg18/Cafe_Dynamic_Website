FROM mysql:latest

ENV MYSQL_DATABASE mom_pop_db
ENV MYSQL_ROOT_PASSWORD Msois@123

COPY mompopdb/create-db.sql /docker-entrypoint-initdb.d/
