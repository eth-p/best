# Best: `skip`

Immediately cause the test to be skipped.



**Arguments:**

 - $1  `[string]`    -- The skip reason (`printf` pattern).
 - ...  `[string]`    -- The pattern arguments.



**Example:**

```bash
skip "Dependency %s is not installed" "tmux"
```

