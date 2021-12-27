# odin-libpq

> Note: These bindings are not exhaustive. There are almost certainly bindings
missing.

This repo contains some Odin bindings for the libpq library. I made these
bindings because I wanted to play around with Odin and Postgres, not because
I planned to put them into production use. I am would not recommend copying
this code and using it in production, but I do hope it proves useful to someone
who might be able to build something more complete.

This repo also contains a helper file which at the moment contains a single
`query` helper. This helper takes a sql query and marshals the result into a
struct.

Please see `example.odin` for some basic usage.

