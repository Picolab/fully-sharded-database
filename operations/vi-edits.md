Extract desired employee lines to a file, say `urk.tsv`
Run these commands to create and run a `bash` file:
```
grep -n . urk.tsv >urk.bash
vi urk.bash #see edits below
chmod +x urk.bash
./urk.bash
```

When using `vi` to edit the `bash` file, make these changes (commands shown here prefixed with colon character):

```
%s/^/echo /
%s/:/; curl -G --data-urlencode "line=/
%s+$+" http://localhost:3000/sky/event/ckryzy1y409904rpb8kqc9vgt/import/byu_hr_oit/import_available; echo; date+
set ff=unix
```

Insert these three lines at the top of the `bash` file:

```
#!/bin/bash

date
```

