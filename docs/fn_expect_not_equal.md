# Best: `expect_not_equal`

Expects one value does not equal another value.



**Arguments:**

 - $1  `[string]`     -- The first value.
 - $2  `[string]`     -- The second value.
- \[$3\]  `"--"`      -- An optional specifier that enables custom failure messages.
- \[$4\]  `[string]`  -- The custom failure message pattern, with "%s" for the values provided.



**Example:**

```bash
expect_not_equal 1 2                # Success
expect_not_equal "no" "no"          # Failure
expect_not_equal 1 1 -- "%s != %s"  # Failure: "Expected 1 != 1"
```

