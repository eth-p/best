# Best: `expect_less`

Expects one value is less than the other value.



**Arguments:**

 - $1  `[string]`     -- The first value.
 - $2  `[string]`     -- The second value.
- \[$3\]  `"--"`      -- An optional specifier that enables custom failure messages.
- \[$4\]  `[string]`  -- The custom failure message pattern, with "%s" for the values provided.



**Example:**

```bash
expect_less 1 2               # Success
expect_less 2 2               # Failure
expect_less 2 1 -- "%s < %s"  # Failure: "Expected 2 < 1"
```

