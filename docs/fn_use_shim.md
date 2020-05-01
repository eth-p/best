# Best: `use_shim`

Loads a shim.

A shim is a Bash script that will be source during setup or test execution.
Shims are intended to replace commands that provide functionality which is either impossible to get inside a non-tty environment, or that would cause the test to never end.



**Arguments:**

 - $1  `[name]`    -- The shim name (the script name without .sh).



**Example:**

```bash
use_shim tput
```
