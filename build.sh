#!/bin/bash

rm odin_libpq_example
odin build example.odin \
  -out=odin_libpq_example \
  -extra-linker-flags="-L/opt/homebrew/opt/libpq/lib -lpq"
