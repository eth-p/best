# Best
A testing framework designed for Bash, and built with Bash.

Minimum Bash version: `3.2.0`  
Supported platforms:
 - GNU Linux
 - MacOS


## Command Line

```shell
bin/best.sh [options] [test...]
```

**Options:**

| Option                | Value      | Description                                                  |
| --------------------- | ---------- | ------------------------------------------------------------ |
| `--jobs` / `-j`       | \[number\] | Specify the number of tests to run in parallel. Defaults to the current number of logical cores. |
| `--suite`             | \[string\] | Loads a specific test suite.<br />If this is absent, all suites in `$PWD/test` will be loaded. |
| `--snapshot:generate` |            | Forces all snapshots to be regenerated.                      |
| `--snapshot:show`     |            | Prints the difference between test output and output snapshots. |
| `--snapshot:skip`     |            | Skips snapshot testing.                                      |
| `--verbose`           |            | Prints STDOUT and STDERR of failed tests.                    |
| `--strict`            |            | Treat skipped tests as though they were failed tests.        |
| `--failed`            |            | Only show failed tests.                                      |
| `--VERBOSE`           |            | Prints STDOUT and STDERR of all tests.                       |
| `--debug`             |            | Prints debug information.<br />This only prints information about `best` itself. |
| `--porcelain`         |            | Changes the printing mode to something machine-friendly.     |
| `--color`             |            | Enable color output.                                         |
| `--no-color`          |            | Disable color output.                                        |

**Subcommands:**

| Subcommand  | Description                                   |
| ----------- | --------------------------------------------- |
| `--list`    | Prints a list of tests in the loaded suites.  |
| `--version` | Prints the version and exits.                 |
| `--repl`    | Enters a minimal REPL similar to the IPC API. |

**Environment Variables:**

| Variable           | Description                                                  | Default          |
| ------------------ | ------------------------------------------------------------ | ---------------- |
| `$BEST_BASH`       | A path to the version of Bash to execute tests with.         |                  |
| `$TEST_ENV_TMPDIR` | The value of `$TMPDIR` inside the testing environment.       | Inherited        |
| `$TEST_ENV_PATH`   | The value of `$PATH` inside the testing environment.         | Inherited        |
| `$TEST_ENV_HOME`   | The value of `$HOME` inside the testing environment.         | Inherited        |
| `$TEST_ENV_TERM`   | The value of `$TERM` inside the testing environment.         | `xterm-color`    |
| `$TEST_LIB_PREFIX` | A variable that prepends a sequence to the test functions. This can be used to prevent function name conflicts with `best` and the scripts that it's testing. | None             |
| `$TEST_SHIM_PATH`  | The path to the shims loadable by `use_shim`.                | None             |
| `$TEST_DIR`        | The directory where test suites are stored.                  | `$PWD/test`      |
| `$SNAPSHOT_DIR`    | The directory where snapshots are stored.                    | `$PWD/test-data` |






## Tests

### Suites

Test suites are located inside `$(PWD)/test` as `.sh` files.

```bash
test:my_test() {
    description 'This is your first test.'

    assert_equal 1 1
    assert [ "a" = "b" ]
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
- [`assert_exit [code]`](docs/fn_assert_exit.md)
- [`expect [function...]`](docs/fn_expect.md)
- [`expect_equal [a] [b]`](docs/fn_expect_equal.md)
- [`expect_not_equal [a] [b]`](docs/fn_expect_not_equal.md)
- [`expect_less [a] [b]`](docs/fn_expect_less.md)
- [`expect_less_or_equal [a] [b]`](docs/fn_expect_less_or_equal.md)
- [`expect_greater [a] [b]`](docs/fn_expect_greater.md)
- [`expect_greater_or_equal [a] [b]`](docs/fn_expect_greater_or_equal.md)
- [`fail [pattern] [...]`](docs/fn_fail.md)
- [`skip [pattern] [...]`](docs/fn_skip.md)
- [`array_contains [value] in [...]`](docs/fn_assert.md)
- [`snapshot ["stdout"|"stderr"]`](docs/fn_snapshot.md)
- [`description [message]`](docs/fn_description.md)
- [`use_shim [name]`](docs/fn_use_shim.md)



### Setup / Teardown

The functions named `setup` and `teardown` are used for test suite setup and teardown.
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
