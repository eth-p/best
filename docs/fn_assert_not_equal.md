# Best: `assert_not_equal`

Asserts one value does not equal another value.
This will exit the test immediately if it fails.



**Arguments:**

 - $1  `[string]`    -- The first value.
 - $2  `[string]`    -- The second value.



**Example:**

```bash
assert_not_equal 1 2       # Success
assert_not_equal "no" "no" # Failure
```

