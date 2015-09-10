# RulzUrAPI
#
# VERSION               0.0.1

FROM       debian
MAINTAINER Maxime Vidori <maxime.vidori@gmail.com>

ENV PGPASSFILE /tmp/.pgpass

# make sure the package repository is up to date
RUN echo "deb http://ftp.fr.debian.org/debian stable main" > \
  /etc/apt/sources.list
RUN echo "deb http://ftp.debian.org/debian/ wheezy-updates main" >> \
  /etc/apt/sources.list

# Add PostgreSQL's repository. It contains the most recent stable release
#     of PostgreSQL, ``9.4``.
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ wheezy-pgdg main" > \
  /etc/apt/sources.list.d/pgdg.list

# Add the PostgreSQL PGP key to verify their Debian packages.
# It should be the same key as
# https://www.postgresql.org/media/keys/ACCC4CF8.asc
RUN apt-key adv --keyserver keyserver.ubuntu.com \
  --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8

RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y postgresql

ADD utils/create_tables.sql /tmp/
ADD utils/clone_schema.sql /tmp/
ADD password ${PGPASSFILE}

RUN chown postgres:postgres ${PGPASSFILE}
RUN chmod 600 ${PGPASSFILE}

# Run the rest of the commands as the ``postgres`` user created by the
# ``postgres-9.4`` package when it was ``apt-get installed``
USER postgres

# Create a PostgreSQL role named ``docker`` with ``docker`` as the password and
# then create a database `docker` owned by the ``docker`` role.
# Note: here we use ``&&\`` to run commands one after the other - the ``\``
#       allows the RUN command to span multiple lines.
RUN /etc/init.d/postgresql start &&\
    psql --command \
    "CREATE USER rulzurdb WITH SUPERUSER PASSWORD '$(cat ${PGPASSFILE})';" &&\
    createdb -O rulzurdb rulzurdb

RUN echo "*:*:rulzurdb:rulzurdb:$(cat ${PGPASSFILE})" > ${PGPASSFILE}
RUN chown postgres:postgres ${PGPASSFILE} && chmod 600 ${PGPASSFILE}

# And add ``listen_addresses`` to ``/etc/postgresql/9.4/main/postgresql.conf``
RUN echo "listen_addresses='*'" >> /etc/postgresql/9.4/main/postgresql.conf

# Adjust PostgreSQL configuration so that remote connections to the
# database are possible.
RUN echo "host all  all    0.0.0.0/0  md5" >> \
  /etc/postgresql/9.4/main/pg_hba.conf


# Init the RulzUrDB tables
RUN /etc/init.d/postgresql start &&\
    sleep 5 &&\
    psql -d rulzurdb -a -f /tmp/create_tables.sql &&\
    psql -d rulzurdb -a -f /tmp/clone_schema.sql

# Expose the PostgreSQL port
EXPOSE 5432

# Add VOLUMEs to allow backup of config, logs and databases
VOLUME  ["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql"]

# Set the default command to run when starting the container
CMD ["/usr/lib/postgresql/9.4/bin/postgres", "-D", \
  "/var/lib/postgresql/9.4/main", "-c", \
  "config_file=/etc/postgresql/9.4/main/postgresql.conf"]
