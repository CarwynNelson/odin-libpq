#!/bin/bash

rm odin_pgsql
odin build main.odin \
  -out=odin_pgsql \
  -extra-linker-flags="-L/opt/homebrew/opt/libpq/lib -lpq"

rm c_pgsq
clang main.c -o c_pgsq \
  -L/opt/homebrew/opt/libpq/lib \
  -I/opt/homebrew/opt/libpq/include \
  -lpq
