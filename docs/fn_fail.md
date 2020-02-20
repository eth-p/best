# Best: `fail`

Immediately fail and abort the test.



**Arguments:**

 - $1  `[string]`    -- The failure reason (`printf` pattern).
 - ...  `[string]`    -- The pattern arguments.



**Example:**

```bash
fail "Could not find file %s" "~/.bash_profile"
```

