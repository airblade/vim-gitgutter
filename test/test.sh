#!/usr/bin/env bash

# TODO: exit with non-zero status code when tests fail.

rm -f *.out

for testcase in test*.vim; do
  vim -N -u NONE -S $testcase -c 'quit!'                        # testFoo.vim
  testname=${testcase%.*}                                       # testFoo
  name=${testname:4}                                            # Foo
  name="$(tr '[:upper:]' '[:lower:]' <<< ${name:0:1})${name:1}" # foo
  expected=$name.ok
  actual=$name.out
  diff $expected $actual && echo "$name ok" || echo "$name failed"
done

git checkout fixture.txt

