# Best: `expect_greater_or_equal`

Expects one value is greater than or equal to the other value.



**Arguments:**

 - $1  `[string]`     -- The first value.
 - $2  `[string]`     -- The second value.
- \[$3\]  `"--"`      -- An optional specifier that enables custom failure messages.
- \[$4\]  `[string]`  -- The custom failure message pattern, with "%s" for the values provided.



**Example:**

```bash
expect_greater_or_equal 2 2                # Success
expect_greater_or_equal 3 2                # Failure
expect_greater_or_equal 1 2 -- "%s >= %s"  # Failure: "Expected 1 >= 2"
```

