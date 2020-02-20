# Best: `snapshot`

Perform snapshot testing.

By default, snapshots will be saved to `$PWD/test-snapshots/[suite]/[test].[type].snapshot`.



**Arguments:**

 - $1  `"stdout"`    -- Perform snapshot testing on STDOUT. 
 - $1  `"stderr"`    -- Perform snapshot testing on STDERR. 



**Example:**

```bash
snapshot stdout
echo "$RANDOM" # Likely to fail.
```

