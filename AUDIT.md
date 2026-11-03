# OrangeDots audit

## 1. Summary

**Audit date:** 2026-11-03. **Reference revision captured during review:** `1a41153a46f584c33709d27e007fcc942621f1c7` (`added ai sidebar`). The audit began with pre-existing dirty changes, including the AI sidebar; at final verification only the two new reports were untracked. No auditor source edits or commits caused that transition. This was a live working-tree audit, not an immutable checkout; references were checked against source at reporting time. See the provenance caveat in `REPORT.md`.

**Stack:** Arch/Hyprland Lua configuration; native Quickshell/Qt Quick QML desktop shell; C++20 Qt plugins built with CMake/Ninja; optional Node.js AI adapters. SQLite stores application launch frequencies. There is no web frontend/backend, Docker deployment, or TypeScript application here.

**Status:** Phases 0–2 only. No application/configuration fixes, branch changes, or commits were made. Only this document and `REPORT.md` were added. Phase 3 requires approval. This is an evidence-backed review of the areas listed in `REPORT.md`, **not a claim that every source file received a complete manual review**; the remaining coverage is explicitly unverified.

**Confirmed findings: 9 total — Critical: 0; High: 2; Medium: 6; Low: 1.** Deliberately requested behavior, such as sidebar auto-approval, is not counted as a vulnerability.

### Baseline results

| Check / measurement | Result |
|---|---|
| Isolated `npm ci --ignore-scripts --no-audit --no-fund` | PASS, 1.857 s; five packages installed |
| `npm audit --json` | PASS, 2.418 s; zero reported advisories at any severity |
| Native Release configure, `plugin;extras` | PASS, 2.419 s |
| Native Release build, Ninja, two jobs | PASS, 163.778 s; 191 build steps |
| Native shared-library file sizes | 4,636,344 bytes total, excluding symlink duplicates; unstripped build output, not an install/bundle size |
| `python3 scripts/check-layout.py` | PASS, 0.136 s; 289 runtime QML sources checked |
| ShellCheck, all seven repository `.sh` files | PASS, 0.531 s; no diagnostics |
| Node syntax checks, five adapter `.mjs` files | PASS |
| Combined AI/weather Node tests | PASS, 17/17, 0.374 s wall time |
| Python unittest discovery | FAIL, 14 pass / 1 error, 12.841 s; A08 |
| Focused QML tests using existing dashboard native build | `ai-memory` PASS 4.518 s; `nexus` PASS 13.039 s; `ai` PASS 10.107 s; `layout` PASS 8.568 s |
| Full QML runner using newly built audit plugins | FAIL after 3.806 s at first layout run: `taskbarWorkspaces should be horizontal: 30x30, horizontal true`; later modes did not run |
| QML static lint/type analysis | `qmllint` exits 255 without diagnostics, including on one file; not a clean lint/typecheck result |
| Existing adapter `node_modules` allocated size | 63 MiB as rounded by `du -sh`; isolated fresh install rounded to 62 MiB |
| Bundled assets allocated size | 9.3 MiB as rounded by `du -sh` |
| Existing live `qs` process sample | RSS 1,221,656 KiB, 79 threads; CPU 0.5% over two seconds. Warm, shared desktop process; not an isolated idle/startup or leak measurement |
| Full desktop startup / web bundle / server idle baseline | Not measured / not applicable; see limitations |

The build excludes the network-fetched `m3shapes` target and real installation. Tools/environment, exact commands, fixture provenance, failures, and evidence outputs are in [`REPORT.md`](REPORT.md).

## 2. Findings table

Paths below are repository-relative. `S/M/L` denotes estimated implementation/testing effort, not priority.

| ID | Severity | Category | Location (file:line) | Problem | Evidence | Proposed fix | Effort (S/M/L) | Risk of fix |
|---|---|---|---|---|---|---|---|---|
| A01 | High | Correctness / data loss | `quickshell/caelestia/plugin/src/Caelestia/cutils.cpp:114-121`; caller `quickshell/caelestia/modules/dashboard/DashboardWrapper.qml:28-36` | Overwriting deletes the existing destination before validating/copying the source. Same-file copies destroy the source; missing/unreadable source or copy failure loses the previous avatar. | Actual freshly built QML `CUtils.copyFile(path, path)` returned false and removed the disposable destination. Extracted production function also returned false and deleted the destination for a missing source. | Recognize identical files and copy into an atomic replacement (`QSaveFile` or equivalent), committing only after successful read/write. Preserve the destination on every failure. Keep the existing API. | M | Medium: preserve overwrite/symlink semantics; test same path, missing source, unwritable target, and valid overwrite. |
| A02 | High | Native concurrency / correctness | `quickshell/caelestia/plugin/src/Caelestia/Services/audiocollector.cpp:186-227`; `audiocollector.hpp:65-68` in the same directory | Atomic pointers do not protect the float buffers. After two producer swaps, the writer can reuse a buffer while a consumer is copying it: a C++ data race/undefined behavior. | ThreadSanitizer on the unchanged production `loadChunk` and float `readChunk` bodies reports concurrent `std::transform` write / `memcpy` read, exit 66. Separate producer/consumer threads exist in the production audio implementation. | Give readers ownership of a stable buffer until their copy finishes; implement a concurrency protocol appropriate for the real-time producer and multiple consumers. Do not casually block the PipeWire RT callback. | M | Medium–High: audio latency, starvation, shutdown, and both reader overloads need stress/sanitizer tests. |
| A03 | Medium | Resource leak / SQLite | `quickshell/caelestia/plugin/src/Caelestia/appdb.cpp:108-122`; `appdb.hpp:73-89` in the same directory | Each `AppDb` creates a uniquely named SQL connection, but there is no destructor closing/removing the connection from Qt's registry. Destroying/reloading objects leaks open database resources. | Program linked against the freshly built core library: `SQL registry connections before=0 after 50 AppDb deletions=50`. | Add lifetime cleanup that closes/removes the named connection after all query/database handles have left scope. | S | Low–Medium: obey Qt connection-removal ordering and test file-backed as well as in-memory databases. |
| A04 | Medium | Correctness / resource statistics | `quickshell/caelestia/services/NetworkUsage.qml:188-218` | Every decrease in summed interface counters is treated as a 64-bit rollover. Interface removal/reset, including reconnecting virtual interfaces, produces impossible rates/totals. | Executing the production arithmetic with previous counters 1,000,000,000, new counters zero, one-second interval yields `18446744072709552000` bytes/s and total bytes. | Rebase/reset samples when interface membership/counters reset; preferably track per-interface counters rather than interpreting aggregate decreases as overflow. | M | Medium: define whether totals mean session accumulation or current-interface totals; retain existing public properties. |
| A05 | Medium | Correctness / persistence recovery | `quickshell/caelestia/services/Notifs.qml:112-125`, persistence gate at `:52-54` | Uncaught malformed history JSON prevents `loaded` from becoming true. Subsequent notifications no longer trigger persistence. | Isolated Quickshell with a disposable malformed `notifs.json`: `SyntaxError: JSON.parse: Parse error`, then `notifs.loaded=false count=0`. | Validate/catch decoding and entry-shape errors, preserve/quarantine bad history, and complete initialization with an empty usable list. | S | Low–Medium: preserve recoverable history; don't silently overwrite the user's only corrupt copy. |
| A06 | Medium | Correctness / stale calendar data | `quickshell/caelestia/services/GoogleCalendar.qml:57-68`, `:80-95`; consumer `quickshell/caelestia/modules/dashboard/Calendar.qml:117-119` | Changing calendar URL does not clear the old feed's events. If the replacement feed fails/returns empty, old events remain displayed under the new configuration. Removing the URL retains them in RAM (the UI does hide them while unconfigured). Old in-flight results are not generation-checked. | Exact URL-read callback replay retains one synthetic old event; reconfiguring a nonempty URL before a usable response makes the consumer expression render that same event. Empty fetch handling only sets an error, not an empty event list. No real calendar URL was read. | Clear cached events/raw content on URL change/disconnect and invalidate/stop old fetches; reject results from earlier URL generations. | S | Low: test removing/replacing a URL, failed replacement fetch, and late old responses. |
| A07 | Medium | Correctness / recording duration | `quickshell/caelestia/services/Recorder.qml:74-80` | Elapsed time increases on every second tick, even when idle or paused; the intended enabling condition is commented out. Paused time is therefore counted as capture time. | Isolated real QML service, without starting a recording: `recorder running=false paused=false before=1 after=2` after emitting a single `Time.secondsChanged()` signal. The same handler has no paused-state guard. | Enable/gate the connection on `running && !paused`, keeping start/reset behavior intact. | S | Low: test idle, recording, pause, resume, and stop. |
| A08 | Low | Test correctness / baseline regression | `tests/test_hypr_modules.py:80-102` versus `hypr/modules/animations.lua:48-95` | Animation test still requires removed `Shell*` curves although the config now deliberately uses `Mac*` curves. The default unittest suite fails before checking the active preset's properties. | Replaying the test's exact Lua harness: `stdin:8: attempt to index a nil value (field 'ShellPanel')`. | Update expectations for the intended active preset, or agree on the desired preset first. Do not revert the user's animation changes to satisfy stale tests. | S | Low after confirming the active preset is intentional. |
| A09 | Medium | Resource leak / Qt subscriptions | `quickshell/caelestia/plugin/src/Caelestia/Services/service.cpp:10-22`; repeated caller `audioprovider.cpp:26-37` in the same directory | Every `ref(sender)` adds a destroyed-signal connection; `unref(sender)` removes the set membership but not that connection. Repeated activation of a long-lived sender accumulates duplicate connections. | Program linked against freshly built services library: `destroyed-signal connections after 1000 ref/unref cycles=1000`. | Keep at most one lifetime connection per sender/service pair, or explicitly disconnect it during unref; retain idempotent ref semantics and automatic destruction cleanup. | S | Low–Medium: test repeated ref, unref, sender destruction, and multiple independent senders. |

## 3. Critical/High verification details

### A01 — A failed copy must not destroy the previous file

The native API defaults `overwrite=true` (`quickshell/caelestia/plugin/src/Caelestia/cutils.hpp:28`). It checks only whether each URL is local, removes an existing target, and **then** calls `QFile::copy`. It neither opens the source first nor handles source/target identity. This is reachable from avatar replacement in the dashboard, not dead code. Selecting a valid source does not guarantee the subsequent copy succeeds (source disappearance, permissions, or write failure).

Two disposable reproductions were used:

1. A QML fixture imported the freshly built core plugin and invoked the actual API on a temporary file, using that file as both source and destination. Output: `AUDIT copy result=false`; afterwards the file did not exist.
2. A minimal Qt program used the production function body without behavioral changes (only removal of the class qualifier and replacement of the logging macro). Both same-file and missing-source cases returned `result=0 destination-exists=0`.

No real `.face`, image, or other personal file was modified. Logs: `/tmp/opencode/orangedots-audit/copyfile-qml-repro.log` and `copyfile-repro.log`.

### A02 — Buffer publication is not reader ownership

The writer fills `m_writeBuffer`, swaps it into `m_readBuffer`, and saves the old read buffer for the next write. The consumer loads the read pointer and copies its non-atomic floats. There is no reader reservation or lock. Another two writes can reuse that buffer before the consumer finishes. Acquire/release publication makes the initial write visible; it does **not** prevent later concurrent mutation.

Production concurrency is explicit: the PipeWire worker is created on a `std::jthread` at `quickshell/caelestia/plugin/src/Caelestia/Services/audiocollector.cpp:243-252`, while processors run on their own `QThread` at `audioprovider.cpp:58-65`; `cavaprovider.cpp:31` consumes the shared buffer.

The isolated stress fixture preserved the exact production `loadChunk` and float `readChunk` bodies, 512-sample vectors, and atomic buffer-pointer arrangement, without Qt/PipeWire plumbing. Two threads performed 20,000 calls each. With `-fsanitize=thread -g -O1 -std=c++20 -pthread`, ThreadSanitizer reported:

```text
WARNING: ThreadSanitizer: data race
Write ... AudioCollector::loadChunk ... std::transform
Previous read ... AudioCollector::readChunk ... memcpy
ThreadSanitizer: reported 1 warnings
```

Exit status was 66. This verifies an unsafe concurrency protocol, not a claim that a live audio crash was reproduced. Source/diagnostics: `/tmp/opencode/orangedots-audit/audio-race-repro.cpp` and `.log`.

## 4. Could not verify

- **Exhaustive file coverage:** the repository contains 293 QML, 57 C++, and 72 C++ header files in the initial inventory. Not all received full manual review. `REPORT.md` lists opened areas and partial coverage; unreviewed files are not certified safe.
- **Concurrent working-tree provenance:** initial tracked modifications were no longer present in final `git status`; the auditor did not commit/reset them. The precise time/source of that external transition is unknown. No immutable tree was frozen, so timings are working-tree observations rather than a guarantee that all commands ran against a single atomic Git snapshot.
- **Full QML regression failure:** the fresh audit build fails the initial workspace-layout assertion, whereas the focused layout run against the existing dashboard build passed. Initialization timing, native-build differences, and actual geometry remain unisolated. No application defect/root cause is asserted from this alone.
- **QML lint/typechecking:** the installed `qmllint` returns 255 without diagnostics on both the aggregate invocation and `services/AiConfig.qml`. This is a validation gap, not evidence that all QML is invalid or valid.
- **Live desktop memory:** the warm process's approximately 1.17 GiB RSS is a point sample, not a leak diagnosis. No before/after heap profile, PSS attribution, GPU allocation measurement, or restart baseline was collected.
- **Audio edge cases:** dequeued buffers with null sample data are returned without requeueing (`audiocollector.cpp:148-162`), and shutdown joins a worker without explicitly waking its event loop (`:255-258`). Real PipeWire reachability/failure conditions were not reproduced; these are not counted as additional findings.
- **AI lifecycle:** closing/reopening during adapter shutdown, distinguishing old process events, missing CLI cancellation deadlines, and default-location/session restoration need process-level race fixtures. Existing mock protocol tests and `ai-memory` are not authenticated end-to-end provider tests.
- **Native DB latency:** per-entry SQLite frequency reads and repeated sorts exist in `appdb.cpp:228-294`, but end-user startup/search latency attributable to them was not measured. The verified connection leak is reported separately.
- **Notification retention:** history has no configured count/byte limit and has per-entry timers. No long-running real notification workload was profiled, and intended retention policy is unspecified; a cap is not proposed as a silent behavior change.
- **Calendar semantics:** recurrence and TZID handling are explicitly limited in source comments. Full iCalendar conformance, unchanged-feed date rollover, malicious feed size, and credential exposure via process arguments were not tested against a real account.
- **Security/dependencies:** npm reports zero advisories; this is not a guarantee about Qt/system packages or native dependencies. Client 2.2.5 exists versus pinned 2.2.1, but no verified exploitable issue was established; no upgrade finding is made merely because a newer release exists.
- **External environment:** no real PAM authentication, sleep/wake, Wi-Fi/VPN connection changes, recording, AI prompt, model download, production install, or desktop restart was performed. `.envrc` content and live secrets were not opened.

## 5. Recommended fix order

1. **A01:** prevent destination data loss; small, isolated API implementation change with strong failure tests.
2. **A09, A03:** stop accumulating Qt connections and SQLite handles; small fixes with direct count assertions.
3. **A02:** repair the audio ownership protocol in a separate commit with sanitizer coverage and latency/shutdown checks. High impact, but requires more design/testing than the small lifetime fixes.
4. **A05:** recover notification persistence from malformed history without deleting the original.
5. **A07, A06:** correct recording-time gating and calendar reconfiguration/late-response cleanup.
6. **A04:** correct counter resets; agree on totals semantics before implementing any changed behavior.
7. **A08:** align the test with the intended animation preset; do not mask the existing baseline failure by reverting unrelated work.
8. Independently isolate the full QML runner failure and restore meaningful static QML checks before claiming a green repository-wide baseline.

**Approval gate:** after approval, create `audit/fixes`, use one logical fix per commit (`fix(area): what and why`), add/run regression tests, rerun applicable checks, and append a before/after baseline table. There is intentionally no after-fix measurement yet.
