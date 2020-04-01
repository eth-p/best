# Best: `expect`

Expects a statement returns true.



**Arguments:**

 -  ... `[string]`    -- The command and arguments to execute.



**Caveats:**

- The bash-specific `[[ a = b ]]` syntax does not work.



**Example:**

```bash
expect [ "hello" = "world" ]
expect ! false
```

