#!/usr/bin/env bash

# TODO: exit with non-zero status code when tests fail.

canonicalise_test_name() {
  local testname=$1                                              # testFoo.vim
  name=${testname%.*}                                            # testFoo
  name=${name:4}                                                 # Foo
  name="$(tr '[:upper:]' '[:lower:]' <<< ${name:0:1})${name:1}"  # foo
}


rm -f *.out

count_ok=0
count_fail=0

for testcase in test*.vim; do
  vim -N -u NONE -S $testcase -c 'quit!'

  canonicalise_test_name $testcase
  expected=$name.ok
  actual=$name.out

  if diff $expected $actual; then
    count_ok=$((count_ok + 1))
    echo "$name ok"
  else
    count_fail=$((count_fail + 1))
    echo "$name failed"
  fi
done

git checkout fixture.txt

echo
echo "$((count_ok + count_fail)) tests"
echo "$count_ok ok"
echo "$count_fail failed"

