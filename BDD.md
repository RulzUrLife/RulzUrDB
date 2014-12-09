# Managing database
Run the database container described [here](./README.md#running-the-database),
then you can run another container to connect to the database container with the
following line: `docker run --rm -v $(pwd):/mnt -t -i --link rulzurdb:rulzurdb rulzurdb bash`.
This line will mount the current directory into `/mnt` so be sure that this command has been
ran into the RulzUrDB folder.

Then, you can manage the database through the command line:

 * simple connection <br/>
 `psql -h $RULZURDB_PORT_5432_TCP_ADDR -p $RULZURDB_PORT_5432_TCP_PORT -d rulzurdb -U rulzurdb`

 * create all tables <br/>
 `psql -h $RULZURDB_PORT_5432_TCP_ADDR -p $RULZURDB_PORT_5432_TCP_PORT -d rulzurdb -U rulzurdb -a -f /mnt/create_tables.sql`

 * delete all tables <br/>
 `psql -h $RULZURDB_PORT_5432_TCP_ADDR -p $RULZURDB_PORT_5432_TCP_PORT -d rulzurdb -U rulzurdb -a -f /mnt/delete_all.sql`

# Database shema


                         +------------------+
                         |recipe ingredients|    +---+------------+
                         +------------------+    |   |ingredient  |
                         |quantity: integer |    |   +------------+
          +--------------+fk_recipe         |    |   |name: string|
          |              |fk_ingredient     +----+   +------------+
          |              |measurement       +----+---+
          |              +------------------+        +-----------------+
          |                                          |measurement: enum|
          |              +---------------+           +-----------------+
          |              |recipe utensils|           |L, g, oz, spoon  |
          |              +---------------+           +-----------------+
          ++-------------+fk_recipe      |
          ||             |fk_utensil     +-----------+------------+
          ||             +---------------+           |utensil     |
          ||                                         +------------+
        +-++-----------------------+                 |name: string|
        |recipe                    |                 +------------+
        +--------------------------+
        |name: string              |     +-----------+------------------------+
        |directions: json          |     |           |duration: enum          |
        |difficulty: integer (0<>6)|     |           +------------------------+
        |people: integer (0<>13)   |     |           |0/5, 5/10, 10/15, etc...|
        |duration                  +-----+           +------------------------+
        |type                      +-----+
        +--------------------------+     +-----------+----------------------+
                                                     |type: enum            |
                                                     +----------------------+
                                                     |starter, main, dessert|
                                                     +----------------------+

