This is Phase 00 runtime case H5. Use the `bash` tool exactly once with exactly
this command:

```text
omp config get task.isolation.mode --json
```

The process PATH intentionally excludes the OMP installation directory. Preserve
the structured bash failure. Do not retry, do not use an absolute OMP path, do not
read configuration files, and do not call `task` or any other tool. Model prose is
not evidence for this case. End with `H5_PARENT_DONE` after the bash result.
