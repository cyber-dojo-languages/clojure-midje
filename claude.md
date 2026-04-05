
Please read https://github.com/cyber-dojo/cyber-dojo/blob/master/docs/how-to-contribute-to-start-points.md
to get an overview of how to work on a start-point.

This repo (`cyber-dojo-languages/clojure-midje`) builds the Docker image.
The start-point files (source, tests, manifest) live in the partner repo:
`../../cyber-dojo-start-points/clojure-midje`

---

## How to work on this repo

Always follow the dev loop:
1. Edit `docker/Dockerfile.base` in this repo (and/or `docker/project.clj`)
2. Run `./pipe_build_up_test.sh` — note the image tag from "Successfully tagged to ..."
3. Update `image_name` in `../../cyber-dojo-start-points/clojure-midje/start_point/manifest.json`
4. Edit start-point files in `../../cyber-dojo-start-points/clojure-midje/start_point/` as needed
5. Run `./run_tests.sh` in the start-points repo — check red/amber/green all PASS

**Never run `docker run ...` directly.** All testing must go through `run_tests.sh`.
To get a baseline or probe the container, temporarily edit `cyber-dojo.sh`, run
`run_tests.sh`, read the output, then restore `cyber-dojo.sh`.

---

## Work done (April 2026)

### Upgraded Midje and lein-midje
- `midje 1.8.3` → `1.10.10`
- `lein-midje 3.2` → `3.2.2`

**Why:** `midje 1.8.3` depends on `marick/suchwow 4.4.3`, which uses a `ns`
require form that Clojure 1.12's stricter spec validation now rejects
(`Extra input spec: :clojure.core.specs.alpha/ns-form`). Upgrading to
`midje 1.10.10` pulls in `marick/suchwow 6.0.3` which is compatible.

### Fixed ANSI colour codes in output
`Dockerfile.base` sets:
```
ENV MIDJE_COLORIZE=false
ENV NO_COLOR=1
```
`MIDJE_COLORIZE=false` suppresses Midje's own pass/fail message colours
(critical — without it the green "All checks succeeded" line is coloured,
which confuses the `rag_lambda`). `NO_COLOR=1` is the no-color.org standard
but is not fully respected by the old `colorize 0.1.1` library or
`io.aviso/pretty 1.4.4` used by Midje 1.10.10 for Expected/Actual values
and stack traces respectively.

`cyber-dojo.sh` therefore pipes stdout through `sed` to strip any remaining
escape codes, preserving lein's exit code via `PIPESTATUS[0]`:
```bash
lein midje | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g'
exit "${PIPESTATUS[0]}"
```

### Added check_version.sh
Checks that `midje 1.10.10` is present in the image's `.m2` cache:
```bash
ls /.m2/repository/midje/midje/
```

### Current state
- `display_name`: `"Clojure 1.12.4, Midje 1.10.10"`
- Base image: `ghcr.io/cyber-dojo-languages/clojure:9a28837`
- `project.clj` (in both `docker/` and `start_point/`):
  - `[org.clojure/clojure "RELEASE"]` (resolves to 1.12.4)
  - `[midje "1.10.10"]`
  - `[lein-midje "3.2.2"]`

---

## Speed (not done, and why)

`clojure-midje` is listed as slow (~5.4s on native AMD64 CI). The baseline
for `lein version` alone is ~1.2s, so ~4s is Midje namespace loading.

### What was tried and failed

**AOT compilation of Midje namespaces:**
Compiled `midje.repl` into `/.midje-classes` via `clojure.lang.Compile`
at image build time, then added `/.midje-classes` to `:resource-paths` so
the pre-compiled `.class` files would be on the classpath at runtime.
Result: `NullPointerException` in `ConcurrentHashMap` — Midje uses dynamic
classloading that breaks when its internals are AOT-compiled.

### What could still be tried

**`clojure` CLI instead of `lein`:**
The `clojure`/`clj` tool has lower startup overhead than `lein`. However,
the base image `ghcr.io/cyber-dojo-languages/clojure:9a28837` only has
`lein` — the `clojure` CLI is not installed. Would need to add it to
`Dockerfile.base`. With it, you could use `deps.edn` instead of `project.clj`
and invoke Midje via `clojure -M -m midje.repl` or similar, potentially
saving 0.5–1s of lein overhead.

**Java directly (bypass lein):**
Pre-compute the classpath at image build time:
```dockerfile
RUN cd /tmp && lein classpath > /.lein-classpath
```
Then in `cyber-dojo.sh`:
```bash
java -cp "$(cat /.lein-classpath):." clojure.main -e \
  "(use 'midje.repl) (System/exit (if (load-facts) 0 1))"
```
Not tried — complexity around Midje's expected REPL environment.
