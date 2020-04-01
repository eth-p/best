# Best: `assert`

Asserts a statement returns true.
This will exit the test immediately if it fails.



**Arguments:**

 -  ... `[string]`    -- The command and arguments to execute.



**Caveats:**

- The bash-specific `[[ a = b ]]` syntax does not work.



**Example:**

```bash
assert [ "hello" = "world" ]
assert ! false
```

