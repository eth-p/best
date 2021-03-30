# Best: `assert_less`

Asserts one value is less than the other value.
This will exit the test immediately if it fails.



**Arguments:**

 - $1  `[string]`     -- The first value.
 - $2  `[string]`     -- The second value.
- \[$3\]  `"--"`      -- An optional specifier that enables custom failure messages.
- \[$4\]  `[string]`  -- The custom failure message pattern, with "%s" for the values provided.



**Example:**

```bash
assert_less 1 2               # Success
assert_less 2 2               # Failure
assert_less 2 1 -- "%s < %s"  # Failure: "Expected 1 < 2"
```

