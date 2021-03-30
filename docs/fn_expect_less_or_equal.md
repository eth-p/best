# Best: `expect_less_or_equal`

Expects one value is less than or equal to the other value.



**Arguments:**

 - $1  `[string]`     -- The first value.
 - $2  `[string]`     -- The second value.
- \[$3\]  `"--"`      -- An optional specifier that enables custom failure messages.
- \[$4\]  `[string]`  -- The custom failure message pattern, with "%s" for the values provided.



**Example:**

```bash
expect_less_or_equal 1 2                # Success
expect_less_or_equal 2 3                # Failure
expect_less_or_equal 2 1 -- "%s <= %s"  # Failure: "Expected 2 <= 1"
```

