# RulzUrAPI
#
# VERSION               0.0.1

FROM       debian:testing
MAINTAINER Maxime Vidori <maxime.vidori@gmail.com>

ENV PGPASSFILE /tmp/.pgpass

RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y postgresql-9.4

ADD utils/create_tables.sql /tmp/

# Run the rest of the commands as the ``postgres`` user created by the
# ``postgres-9.4`` package when it was ``apt-get installed``
USER postgres
ARG PASSWORD

# Create a PostgreSQL role named ``docker`` with ``docker`` as the password and
# then create a database `docker` owned by the ``docker`` role.
# Note: here we use ``&&\`` to run commands one after the other - the ``\``
#       allows the RUN command to span multiple lines.
RUN pg_ctlcluster 9.4 main start && \
    psql -c "CREATE USER rulzurdb WITH CREATEDB PASSWORD '${PASSWORD}'" && \
    pg_ctlcluster 9.4 main stop

RUN echo "*:*:rulzurdb:rulzurdb:${PASSWORD}" > ${PGPASSFILE}
RUN echo "*:*:rulzurdb_test:rulzurdb:${PASSWORD}" >> ${PGPASSFILE}
RUN echo "*:*:template1:rulzurdb:${PASSWORD}" >> ${PGPASSFILE}

RUN chown postgres:postgres ${PGPASSFILE} && chmod 600 ${PGPASSFILE}

# And add ``listen_addresses`` to ``/etc/postgresql/9.4/main/postgresql.conf``
RUN sed -ri \
    "s/#listen_addresses = '.*?'(.*)/listen_addresses = '*'        \1/" \
    /etc/postgresql/9.4/main/postgresql.conf

# Adjust PostgreSQL configuration so that remote connections to the
# database are possible.
RUN sed -i \
    "87ahost    all             all             0.0.0.0/0               md5" \
    /etc/postgresql/9.4/main/pg_hba.conf


# Expose the PostgreSQL port
EXPOSE 5432

# Add VOLUMEs to allow backup of config, logs and databases
VOLUME  ["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql"]

# Set the default command to run when starting the container
CMD pg_ctlcluster 9.4 main start && \
    tail -f /var/log/postgresql/postgresql-9.4-main.log
