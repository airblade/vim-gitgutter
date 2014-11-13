## Testing vim-gitgutter

### Run the tests

```sh
$ cd test
$ ./test.sh
```

### Add a new test

- Add a test file named like `testFoo.vim`.  It should have this structure:

```viml
source helper.vim
call Setup()

" test code here

quit!
```

- Run the tests.
- Inspect output from the new test.  If good, copy it to `foo.ok`.
- Run the tests to ensure new test's output is verified.
- `rm *.out` and commit changes.
