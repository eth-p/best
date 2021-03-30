# Best: `assert_greater`

Asserts one value is greater than the other value.
This will exit the test immediately if it fails.



**Arguments:**

 - $1  `[string]`     -- The first value.
 - $2  `[string]`     -- The second value.
- \[$3\]  `"--"`      -- An optional specifier that enables custom failure messages.
- \[$4\]  `[string]`  -- The custom failure message pattern, with "%s" for the values provided.



**Example:**

```bash
assert_greater 2 1               # Success
assert_greater 3 2               # Failure
assert_greater 1 2 -- "%s > %s"  # Failure: "Expected 1 > 2"
```

