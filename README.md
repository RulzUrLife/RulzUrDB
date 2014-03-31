RulzUrDB
========

The application database, this database will be available internally,
 external functions will be provided by the API.


# Technologies

 * Riak: a document distributed database,
 [official website](http://basho.com/riak/).

# Management script
Usage: `./manage.py [task [task options]]` help is available with
`./manage.py -h`.

## install
Requirements: to run the install commands you need to have VirtualBox installed
 for OSX or Ubuntu at least 12.04.

Usage: `./manage.py install [options]`, options can be combined.

* -d, --docker: install docker with (with boot2docker on OSX)

If no option is specified, the install will perform a `-a` by default.

Help is available with `./manage.py install -h`

## docker
Usage `./manage.py docker [options]`, options can be combined.

* -b, --build: build the docker container
* -c, --clean: clean docker runtime (stop and remove containers)
* -r, --run  : run the dedicated docker container
* -s, --ssh  : connect to the docker container through ssh (for debug purpose)

Help is available with `./manage.py docker -h`
