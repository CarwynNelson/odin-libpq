# odin-libpq

> Note: These bindings are not exhaustive. There are almost certainly bindings
missing.

This repo contains some Odin bindings for the libpq library. I made these
bindings because I wanted to play around with Odin and Postgres, not because
I planned to put them into production use. I  would not recommend copying
this code and using it in production, but I do hope it proves useful to someone
who might be able to build something more complete.

This repo also contains a helper file which at the moment contains a single
`query` helper. This helper takes a sql query and marshals the result into a
struct.

Please see `example.odin` for some basic usage. There is currently only a bash
build script which has only been tested on an M1 Macbook Pro.

In order to build and run:
```sh
./build.sh
./odin_libpq_example
```

The schema I have used for `example.odin` is:
```sql
create table people (
  number integer not null,
  small_num smallint not null,
  big_num bigint not null,
  small_float real not null,
  big_float double precision not null,
  name varchar(255) not null
)
```

And to insert some example data:
```sql
insert into people (name, number, small_num, big_num, small_float, big_float) values
  ('Jane Doe', 1, 10, 1000, 10.2, 1000.234),
  ('John doe', 2, 20, 2000, 20.4, 2000.487)
```
