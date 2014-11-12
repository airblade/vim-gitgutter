#!/usr/bin/env bash

rm -f *.out

# Run the tests.
vim -N -u NONE -S test.vim

# Verify the outputs.
for expected in *.ok; do
  name=${expected%.*}
  actual=$name.out
  diff $expected $actual && echo "$name ok" || echo "$name failed"
done
