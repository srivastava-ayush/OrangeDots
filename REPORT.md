# Audit execution report

## Scope and change policy

Audit conducted on 2026-11-03 in `/home/ayush/OrangeDots`. It began with pre-existing working-tree modifications, including AI-sidebar work and unrelated animation changes. The Git reference captured during review was `1a41153a46f584c33709d27e007fcc942621f1c7` (`added ai sidebar`). This was **a live working-tree audit, not a frozen pristine checkout**.

**Provenance caveat:** final `git status --short` listed only `?? AUDIT.md` and `?? REPORT.md`, whereas the initial status listed numerous source modifications/untracked AI files. No auditor command committed, reset, or edited those files. The exact time/source of that external transition was not recorded; it must not be attributed to the auditor or assumed to be a particular user action. File/line evidence was checked at reporting time. Because no immutable snapshot was taken, baseline commands are working-tree observations, not proof of one atomic Git-tree benchmark.

The required findings format, severity counts, file/line references, verified evidence, proposed fixes, effort, and risks are in [`AUDIT.md`](AUDIT.md). This file records orientation, commands, measurements, fixture methodology, and limits. Both are Phase 2 deliverables. No Phase 3 fixes are authorized or applied.

- Preserved pre-existing modified/untracked files; no reset, checkout, branch switch, or commit.
- No application source/configuration was changed during the audit. Added only `AUDIT.md` and `REPORT.md`.
- Builds, dependency installation, reproduction sources/executables, and logs use `/tmp/opencode/orangedots-audit/`, not the source tree or production install. Standard test invocations may generate ignored Python bytecode.
- No secret files, real calendar contents, credentials, AI prompts, or database contents were printed. `.envrc` was inventoried by filename only.
- No real shell restart, authentication, recording, network reconfiguration, model generation, `sudo`, or system installation was run.
- Logs/fixtures under `/tmp/opencode` are disposable evidence, not committed tests. The essential outputs/methodology are included here and in `AUDIT.md` so conclusions do not depend solely on temporary paths.

## Phase 0 — repository map

| Top-level path | Role |
|---|---|
| `hypr/` | Lua Hyprland entry/configuration modules, active colour scheme, helper scripts |
| `quickshell/caelestia/` | Live vendored/forked shell: QML UI/services, C++ Qt plugins, assets, tests, optional AI adapter package |
| `caelestia/` | Committed first-install JSON presets, not live private state |
| `scripts/` | Python installer and runtime/source layout checker |
| `tests/` | Isolated installation, Hyprland registration, and AI adapter unittest bridge |
| `docs/` | Source/feature/installation documentation |
| `install.sh` | Bash wrapper around the safe Python config installer |
| `refresh-rate-toggle.sh` | Compatibility wrapper for the Hyprland refresh helper |
| `AGENTS.md`, `README.md`, `.gitignore` | Repository guidance and development/install instructions |

### Manifests / tooling / environment inventory

- One npm application package: `quickshell/caelestia/utils/opencode/package.json` with `package-lock.json`. It pins the only direct dependency, `@opencode/client`, to 2.2.1; no npm build/lint/typecheck scripts are defined.
- `quickshell/caelestia/CMakeLists.txt` plus plugin/extras and per-native-module CMake files. C++20, Qt >= 6.9; the build uses private Qt Wayland interfaces and emits the corresponding ABI warning.
- No `tsconfig`, TypeScript frontend, Dockerfiles, CI workflow files, or `.env.example` discovered in the source inventory. No `.env` content was opened. `quickshell/caelestia/.envrc` exists; its content was intentionally not read.
- Initial source inventory excluding `.git`, `node_modules`, build/cache/bytecode directories: 293 `.qml`, 57 `.cpp`, 72 `.hpp`, 14 `.lua`, 7 `.sh`, 8 `.py`, and 6 `.mjs`. One `.mjs` is a test; five are adapter runtime files. Layout validation intentionally counts 289 runtime QML sources, excluding test fixtures.
- Tools available: Node v26.12.1; npm 12.2.1; CMake 4.4.5; Python 3.14.8; Qt 6.12.0; Ninja; Lua/luac; ShellCheck 0.11.0; `qs`; `qmllint` (version output `1.0`). `knip` and `depcheck` are not installed. Their absence is not a finding.

### Boot and execution model

1. `hypr/hyprland.lua:6-31` invalidates/reloads explicit Lua modules. `hypr/modules/autostart.lua:6-11` launches `caelestia shell -d` from the compositor startup event, alongside optional desktop helpers.
2. `quickshell/caelestia/shell.qml:17-55` is the Quickshell entry point: font/service loading, background, per-screen desktop, screenshot tools, session lock, shortcuts, switcher, battery/idle handling. It is not an HTTP server.
3. `modules/ServiceLoader.qml:7-21` eagerly initializes selected service singletons; `modules/launcher/LauncherWrapper.qml:41` preloads app metadata. Most panel content uses loaders.
4. `modules/desktop/` composes the taskbar, drawer geometry/backgrounds, input regions, focus, and hover/gesture routing. QML stays interpreted; native plugins are CMake-built.
5. `modules/ai/AiChatState.qml:225-249` owns a Node adapter process. `utils/opencode/entry.mjs` chooses provider implementations. OpenCode uses its shared authenticated service; Codex/Claude use child CLIs; Ollama uses local HTTP. No ordinary chat terminal/webview is required.
6. `CMakeLists.txt:64-76` installs QML/assets/services/utilities recursively. `scripts/install.py` links source and seeds only missing presets; it does not build or install system dependencies.

## Baseline commands and results

Wall times below are single-run observations, not statistical benchmarks; independent checks sometimes ran concurrently. The initial build attempt was accidentally given a 1,000 ms harness timeout and terminated before recording configure output; no `cmake` process remained before retry. The complete successful retry is the build baseline. The retry therefore reused a partially initialized build directory; it was a full compilation of native targets, not a rigorously cold-filesystem benchmark.

### Dependencies

Copied just the npm manifest and lockfile to `/tmp/opencode/orangedots-audit/npm/`, then ran there:

```sh
npm ci --ignore-scripts --no-audit --no-fund
npm audit --json
npm outdated --json
npm ls --all
```

- Install: exit 0, 1.857 s, five installed packages.
- Audit: exit 0, 2.418 s; vulnerabilities: info=0, low=0, moderate=0, high=0, critical=0.
- Dependency tree: client 2.2.1; protocol/schema 2.2.1; `effect` 4.0.1; `@standard-schema/spec` 1.1.0. Optional `solid-js` peer is absent and is not needed by this Node adapter.
- `npm outdated` exit 1 reports latest client 2.2.5, wanted/current 2.2.1. This is an update notice, **not a verified security issue**.
- Existing adapter dependency directory: `du -sh` rounds to 63 MiB; isolated fresh install rounds to 62 MiB. Allocated disk size is not runtime RAM or a browser bundle size.
- Direct dependency usage is visible in `utils/opencode/bridge.mjs`; no unused direct dependency was established. No extra analyzer package was installed merely to run depcheck/knip.

Logs: `npm-ci.log`, `npm-audit.log`, `npm-outdated.log` under the evidence directory.

### Build / install

```sh
cmake -S quickshell/caelestia \
  -B /tmp/opencode/orangedots-audit/native-build -G Ninja \
  -DVERSION=0.0.0 -DGIT_REVISION=audit-baseline \
  '-DENABLE_MODULES=plugin;extras' -DCMAKE_BUILD_TYPE=Release
cmake --build /tmp/opencode/orangedots-audit/native-build -j 2
```

- Configure: exit 0, 2.419 s.
- Build: exit 0, 163.778 s, 191 steps. Build log includes Qt private-Wayland-API ABI warnings; this is a documented compatibility boundary, not independently a finding.
- Total regular non-symlink `.so` file bytes under build output: **4,636,344**. These are unstripped native build artifacts, not total installed footprint. The `qml/` directory mostly contains links/metadata and its `du` figure alone is not the plugin size.
- The documented `m3shapes` fetch/build and real system install were not run. Staged **shell-only** CMake installation is covered by the existing unittest suite and passed.
- No web bundle exists to measure. Runtime source/assets sizes: modules 1.5 MiB; assets 9.3 MiB; plugin source 896 KiB, rounded allocated sizes. Largest assets: wallpaper WebP 5,571,692 bytes; bundled variable font 3,997,148 bytes; `dino.png` 9,441 bytes. Size alone is not reported as a defect.

Logs: `configure.log`, `build.log`, `baseline-build.json`.

### Lint / static checks

```sh
python3 scripts/check-layout.py
shellcheck install.sh refresh-rate-toggle.sh \
  hypr/scripts/toggle-refresh-rate.sh hypr/scripts/toggle-shell.sh \
  hypr/scripts/toggle-spotify.sh quickshell/caelestia/assets/wrap_term_launch.sh \
  quickshell/caelestia/scripts/install-lock-render-recovery.sh
# Each of the five runtime adapter modules:
node --check quickshell/caelestia/utils/opencode/entry.mjs
# ...also bridge.mjs, bridge-core.mjs, providers.mjs, codex.mjs
```

- Layout: exit 0, 0.136 s, 289 runtime QML sources.
- ShellCheck: exit 0, 0.531 s, no diagnostics. Missing strict-mode prologues were not automatically treated as bugs; no demonstrated shell-script failure was found from this check.
- All adapter syntax checks pass. Lua parse checks pass within unittest discovery.
- Aggregate `qmllint -I /tmp/opencode/orangedots-audit/native-build/qml <all runtime QML paths>` returned 255 in 0.030 s with **no output**. Retrying a single file (`qmllint quickshell/caelestia/services/AiConfig.qml`) also returned 255 without diagnostics. There is no passing comprehensive QML typecheck/lint result. No TypeScript typecheck exists.

Logs: `layout.log`, `shellcheck.log`, `qmllint.log`, `baseline-checks.json`.

### Tests

```sh
python3 -m unittest discover -s tests -v
node --test quickshell/caelestia/tests/ai-bridge.test.mjs \
  quickshell/caelestia/tests/weather.test.cjs
QML_IMPORT_PATH=/tmp/opencode/orangedots-dashboard-build/qml \
  python3 quickshell/caelestia/tests/integration.py --mode ai-memory
# Same command with modes nexus, ai, layout.
QML_IMPORT_PATH=/tmp/opencode/orangedots-audit/native-build/qml \
  python3 quickshell/caelestia/tests/integration.py
```

| Invocation | Result | Wall time |
|---|---|---:|
| Python unittest discovery | 15 tests; 14 pass, 1 error (A08) | 12.841 s |
| Combined Node tests | 17 pass, no failures | 0.374 s |
| Existing-build `ai-memory` | PASS | 4.518 s |
| Existing-build `nexus` | PASS | 13.039 s |
| Existing-build `ai` | PASS | 10.107 s |
| Existing-build `layout` | PASS | 8.568 s |
| Fresh-build full QML runner | FAIL at initial layout assertion; subsequent modes not executed | 3.806 s |

Full-run error: `TASKBAR TEST FAIL: taskbarWorkspaces should be horizontal: 30x30, horizontal true`. This is recorded as a baseline failure; the precise application/test/build root cause is not established. The earlier focused-mode successes must not be generalized to the full runner.

The unittest animation failure was investigated by extracting and replaying its **exact** Lua harness, which yields `stdin:8: attempt to index a nil value (field 'ShellPanel')`. The active Lua config defines `MacOpen`, `MacClose`, etc.; this source-of-truth disagreement is A08.

Logs: `unittest.log`, `node-tests.log`, `integration-{ai-memory,nexus,ai,layout}.log`, `integration-full.log`, `animation-repro.log`; metric JSON files `baseline-checks.json`, `baseline-integration.json`, `baseline-full.json`.

### Startup / idle resources

Read `/proc/76650/status` and CPU tick deltas without changing the running desktop:

```text
VmRSS:   1221656 kB
VmSize:  3890064 kB
Threads: 79
two-second sampled CPU: 0.5%
```

This was a **warm existing desktop process**, not a controlled idle process. Its UI state/reload history were not normalized; process-wide RSS includes shared/native allocations. Do not attribute this number to the sidebar, SQL leak, or any single component. No full desktop startup measurement was taken because starting/restarting a production shell would change desktop behavior. There is no repository web server to benchmark. Isolated QML fixture/test runtimes are reported separately, not mislabeled as server startup time.

## Phase 1 — review and evidence ledger

### Opened areas and applicability

Full-file reads covered repository installer/layout scripts and all seven shell scripts; Hyprland entry/autostart/animation files and its tests; the shell entry/service loader; AI state, UI/wrapper/settings/config and all five adapter implementations; desktop input/interaction/layout code; launcher wrapper/app/search code; switcher state; lock root/PAM flow; screenshot entry/recorder; notification state/history; calendar, weather, network usage, phone, audio, brightness, and player services; and native CMake, file-copy, app database, image cache/provider, requests, GPU, storage/session manager, audio collector/provider/Cava, ticking-service and service-ref lifetimes. Source files previously opened during the sidebar task were also available as context; that does not imply all related files were reviewed for this audit.

Partial reads/searches covered the much larger `Nmcli.qml` and `VPN.qml`, ancillary settings controls and file-dialog/source-map documentation. **Not every QML widget, C++ module/header, parser, test fixture, or Lua module was manually opened in full.** Automated parsing/layout checks do not substitute for that work. Complete repository coverage remains unverified rather than being implied by the nine findings.

Applicable audit areas addressed:

- Correctness: native lifetime/concurrency, copy failure semantics, malformed persistence, stale async/UI data, timers/statistics, AI command/stream lifecycle.
- Shell scripts/app boot: full shell-script reads/ShellCheck, installer safety, eager versus loader-driven QML service startup. No npm lifecycle scripts, Docker RUN steps, or CI pipelines exist to audit here.
- Performance/resources: native database/signal lifetimes, audio buffer ownership, polling gates, cached state, startup dependencies, image handling. Frontend re-render/memoization, `.lean()`, HTTP controller auth, and web bundling do not apply to this QML desktop repository.
- Dependency/security hygiene: isolated lockfile install, npm audit/tree/outdated checks, arrays versus shell command construction in opened code, private data handling and the user-requested sidebar auto-approval boundary. No unsupported claim of a secure/exploit-free repository is made.

### Confirmed reproductions

| ID | Disposable fixture and method | Observed output |
|---|---|---|
| A01 | `copyfile-repro.cpp`: exact production copy function body, logging macro/class-qualifier adaptation only; `copyfile-qml-repro.log`: actual freshly built plugin invoked by isolated QML | Same-file and missing-source cases: `result=0 destination-exists=0`. Actual QML: `AUDIT copy result=false`, destination exists `False`. |
| A02 | `audio-race-repro.cpp`: unchanged `loadChunk`/float `readChunk` method bodies, matching 512-element vectors/atomic pointers; two threads, 20,000 operations each; GCC ThreadSanitizer | Exit 66; `WARNING: ThreadSanitizer: data race`; writer transform overlaps reader memcpy. This is an algorithm stress reproduction, not live PipeWire crash evidence. |
| A03 | `appdb-repro.cpp`: instantiate/delete 50 real `caelestia::AppDb` objects, linked to fresh `libcaelestia-core.so`, inspect `QSqlDatabase::connectionNames()` | `SQL registry connections before=0 after 50 AppDb deletions=50`. |
| A04 | `service-repro.mjs`: production counter delta/rollover arithmetic with synthetic previous=1,000,000,000 and current=0 at one second | `{"speed":18446744072709552000,"total":18446744072709552000}`. |
| A05 | Isolated actual Quickshell service with malformed disposable `XDG_STATE_HOME/caelestia/notifs.json` | `SyntaxError: JSON.parse: Parse error`; `AUDIT notifs.loaded=false count=0`. |
| A06 | `service-repro.mjs`: exact URL-read response callback with blank text and one synthetic cached event, then a replacement configured URL; replay the UI's configured/events selection | Removed URL retains one event; replacement URL before usable response: `{"configured":true,"renderedEvents":1}`. The actual UI hides old events while URL is empty, but not while a different nonempty URL fails to fetch. |
| A07 | Isolated actual `Recorder`/`Time` services; no record start/stop calls; emit one seconds-changed signal after startup | `AUDIT recorder running=false paused=false before=1 after=2`. |
| A08 | Exact existing animation test Lua harness replayed against current `animations.lua` | `attempt to index a nil value (field 'ShellPanel')`. |
| A09 | `service-connections-repro.cpp`: subclass real freshly built `Service`, ref/unref one long-lived QObject 1,000 times, expose QObject receiver count | `destroyed-signal connections after 1000 ref/unref cycles=1000`. |

All fixture sources/logs live beneath `/tmp/opencode/orangedots-audit/`. C++ fixtures were built with `c++ -fPIC -std=c++20` and `pkg-config --cflags --libs Qt6Core` (plus Qt6Qml/Qt6Sql where needed); actual-library fixtures use the new build's library path/rpath. Audio uses `c++ -fsanitize=thread -g -O1 -std=c++20 -pthread`. These are synthetic inputs and disposable data only.

The QML fixtures use symlinks to the source module trees but isolated HOME/XDG directories, an invalid disposable session-bus address, unset compositor signature, and the new native build's QML import path. They neither lock the session nor start a recording. The malformed notification JSON contains only a fixed fixture string. File-copy fixtures target only the disposable audit directory.

An initial standalone copy-fixture link failed because Qt symbols require position-independent compilation on this host; adding `-fPIC` fixed the fixture build. An initial QML copy fixture invoked `Qt.quit()` during component construction and timed out; the successful reproduction runs it from a timer after startup. Both were fixture setup issues, not findings. Their temporary processes were terminated by the subprocess timeout; the final actual-plugin reproduction completed normally.

## Phase 2 outcome and next gate

Nine findings are confirmed with evidence and cited in `AUDIT.md`: two High, six Medium, one Low. Baseline failures and uncertain/unreviewed areas are kept separate. There is no before/after performance claim because no fixes were applied.

**Stopped for approval.** Upon approval, Phase 3 must create `audit/fixes`, preserve existing work, implement one justified logical fix per commit, keep public APIs/schemas/env names unchanged unless separately approved, run practical failing regression tests first, rerun build/static checks/tests after fixes, and remeasure the documented baselines. Pre-existing failing tests must remain clearly distinguishable from any new regression; do not reset unrelated work to obtain a green result.
