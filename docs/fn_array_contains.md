# Best: `array_contains`

Checks that an array contains a value.


#
#
# Arguments:
#
# Example:
#
#     array_contains "world" in "${MY_ARRAY[@]}"
#

**Arguments:**

 - $1  \[string\]    -- The value to check.
 - $2  "in"        -- The string "in".
 - ... \[string\]    -- The array contents.


**Example:**

```bash
assert array_contains "a" in "a" "b" "c" "d"
```

