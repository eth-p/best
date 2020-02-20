# Best
A testing framework designed for Bash, and built with Bash.



## Command Line

```shell
bin/best.sh [options] [test...]
```

**Options:**

| Option                | Value      | Description                                                  |
| --------------------- | ---------- | ------------------------------------------------------------ |
| `--suite`             | \[string\] | Loads a specific test suite.<br />If this is absent, all suites in `$PWD/test` will be loaded. |
| `--snapshot:generate` |            | Forces all snapshots to be regenerated.                      |
| `--snapshot:show`     |            | Prints the difference between test output and output snapshots. |
| `--verbose`           |            | Prints STDOUT and STDERR of failed tests.                    |
| `--VERBOSE`           |            | Prints STDOUT and STDERR of all tests.                       |
| `--debug`             |            | Prints debug information.<br />This only prints information about `best` itself. |
| `--porcelain`         |            | Changes the printing mode to something machine-friendly.     |
| `--color`             |            | Enable color output.                                         |
| `--no-color`          |            | Disable color output.                                        |

**Subcommands:**

| Subcommand | Description                                  |
| ---------- | -------------------------------------------- |
| `--list`   | Prints a list of tests in the loaded suites. |





## Tests

### Suites

Test suites are located inside `$(PWD)/test` as `.sh` files.

```bash
test:my_test() {  
    description 'This is your first test.'
    
    assert_equal 1 1
    assert [[ "a" = "b" ]]
}
```



### Functions

- [`assert [function...]`](docs/fn_assert.md)
- [`assert_equal [a] [b]`](docs/fn_assert_equal.md)
- [`assert_not_equal [a] [b]`](docs/fn_assert_not_equal.md)
- [`assert_less [a] [b]`](docs/fn_assert_less.md)
- [`assert_less_or_equal [a] [b]`](docs/fn_assert_less_or_equal.md)
- [`assert_greater [a] [b]`](docs/fn_assert_greater.md)
- [`assert_greater_or_equal [a] [b]`](docs/fn_assert_greater_or_equal.md)
- [`fail [pattern] [...]`](docs/fn_fail.md)
- [`snapshot ["stdout"|"stderr"]`](docs/fn_snapshot.md)

### 

### Setup / Teardown

The functions named `setup` and `teardown` will be used for test suite setup and teardown.
The former will be called when the suite is loaded, and the latter will be called after all tests are run.

```bash
setup() {
	MY_VAR=3
}

teardown() {
	unset MY_VAR
}

test:check_setup() {
  assert_equal "$MY_VAR" 3
}
```
