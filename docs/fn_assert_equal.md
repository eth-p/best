# Best: `assert_equal`

Asserts one value equals another value.
This will exit the test immediately if it fails.



**Arguments:**

 - $1  `[string]`     -- The first value.
 - $2  `[string]`     -- The second value.
- \[$3\]  `"--"`      -- An optional specifier that enables custom failure messages.
- \[$4\]  `[string]`  -- The custom failure message pattern, with "%s" for the values provided.



**Example:**

```bash
assert_equal 1 1                      # Success
assert_equal "yes" "no"               # Failure
assert_equal 1 2 -- "%s to equal %s"  # Failure: "Expected 1 to equal 2"
```

