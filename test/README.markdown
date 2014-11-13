## Testing vim-gitgutter

### Run the tests

```sh
$ cd test
$ ./test
```

### Add a new test

- Add a test file named like `testFoo.vim`.  It should have this structure:

```viml
source helper.vim
call Setup()

" test code here
```

- Run the tests.
- Inspect output (in `foo.actual`) from the new test.  If good, copy it to `foo.expected`.
- Run the tests to ensure new test's output is verified.
- Commit changes.

### Limitations

- Currently tests are done by writing out a file and comparing it to a known good one.
- There's no support for assertions within the testcase code.

