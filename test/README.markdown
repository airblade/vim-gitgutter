## Testing vim-gitgutter

### Run the tests

```sh
$ cd test
$ ./test.sh
```

### Add a new test

1. Add new test function to `test.vim`.
2. Add a call to the test function in `test.vim`.
3. Run the tests.
4. Inspect output from the new test function.  If good, copy it to `<blah>.ok`.
5. Run the tests to ensure new test's output is verified.
6. `rm *.out` and commit changes.

### Potential test pitfalls

Currently the tests are order-dependent because the sign id counter isn't reset between tests.
