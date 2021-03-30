# Best: `assert_greater_or_equal`

Asserts one value is greater than or equal to the other value.
This will exit the test immediately if it fails.



**Arguments:**

 - $1  `[string]`     -- The first value.
 - $2  `[string]`     -- The second value.
- \[$3\]  `"--"`      -- An optional specifier that enables custom failure messages.
- \[$4\]  `[string]`  -- The custom failure message pattern, with "%s" for the values provided.



**Example:**

```bash
assert_greater_or_equal 2 2                # Success
assert_greater_or_equal 3 2                # Failure
assert_greater_or_equal 1 2 -- "%s >= %s"  # Failure: "Expected 1 >= 2"
```

