# RulzUrAPI
#
# VERSION               0.0.1

FROM       debian
MAINTAINER Maxime Vidori <maxime.vidori@gmail.com>

ENV PGPASSWORD "rulzurdb"

# make sure the package repository is up to date
RUN echo "deb http://ftp.fr.debian.org/debian stable main" > /etc/apt/sources.list
RUN echo "deb http://ftp.debian.org/debian/ wheezy-updates main" >>\
    /etc/apt/sources.list

RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y postgresql

# Adjust PostgreSQL configuration so that remote connections to the
# database are possible.
RUN echo "host all  all    0.0.0.0/0  md5" >>\
    /etc/postgresql/9.1/main/pg_hba.conf

# Run the rest of the commands as the ``postgres`` user created by the
# ``postgres-9.1`` package when it was ``apt-get installed``
USER postgres

COPY create_tables.sql /tmp/

# Create a PostgreSQL role named ``docker`` with ``docker`` as the password and
# then create a database `docker` owned by the ``docker`` role.
# Note: here we use ``&&\`` to run commands one after the other - the ``\``
#       allows the RUN command to span multiple lines.
RUN /etc/init.d/postgresql start &&\
    psql --command "CREATE USER rulzurdb WITH SUPERUSER PASSWORD 'rulzurdb';" &&\
    createdb -O rulzurdb rulzurdb

# And add ``listen_addresses`` to ``/etc/postgresql/9.1/main/postgresql.conf``
RUN echo "listen_addresses='*'" >> /etc/postgresql/9.1/main/postgresql.conf

# Init the RulzUrDB tables
RUN /etc/init.d/postgresql start &&\
    psql -d rulzurdb -a -f /tmp/create_tables.sql

# Expose the PostgreSQL port
EXPOSE 5432

# Add VOLUMEs to allow backup of config, logs and databases
VOLUME  ["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql"]

# Set the default command to run when starting the container
CMD ["/usr/lib/postgresql/9.1/bin/postgres", "-D", "/var/lib/postgresql/9.1/main", "-c", "config_file=/etc/postgresql/9.1/main/postgresql.conf"]
