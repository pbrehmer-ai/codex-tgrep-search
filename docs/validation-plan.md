# Validation plan

**Runtime validation not executed.** This document specifies the next stage, not passed installation, behavior, or performance tests.

Publication checks on September 10, 2026: independent source reviews completed; PowerShell syntax parsing passed without executing the installer; relative Markdown links and basic skill name/description constraints passed. The bundled `quick_validate.py` could not run because its PyYAML dependency was unavailable. Frontmatter was reviewed manually; full YAML/tool validation remains a pilot check. No tgrep executable, installer, index, server, or Codex behavior test was run.

## Setup and recovery

Use a disposable Windows user/Codex profile before touching an employee's normal instructions. Cover x64 and ARM64 where available, PowerShell 5.1+, spaces in paths, a custom `CODEX_HOME`, and an existing external executable.

Verify that `-WhatIf` makes no writes or network requests; default downloads match their digests; a bad digest installs no executable; `-TgrepPath` performs no download/execution; and missing payload files fail before installation. Check repeat setup and partial failure recovery using the recorded exact original bytes.

Exercise absent, populated, whitespace-only, and BOM-only `AGENTS.override.md`, populated base instructions, UTF-8 with/without BOM, and rejected unsupported encodings. Simulate changes to either global file during preparation. Ensure setup preserves unrelated text and chooses the same effective file as the target Codex version. Check neither PATH nor `config.toml` changes.

## Codex behavior

Start fresh tasks under the intended profile. Observe actual skill reads and shell commands, not only Codex's verbal statement that it uses tgrep.

| Scenario | Evidence to collect |
| --- | --- |
| Normal coding request, no tgrep mention | Skill selected or read via installed path; tgrep used for suitable text discovery. |
| Explicit `$codex-tgrep-search` | Correct skill and references loaded without requiring another product's settings. |
| Several related code searches | Root/executable/status reused, selective queries grouped when useful, compact relevant output. |
| Known file or tiny one-off lookup | Direct access; no unnecessary index build. |
| Warm large checkout | Existing server reused; no repeated status checks or file inventories. |
| Fresh or resumed index build | Empty/partial results never treated as exhaustive absence. |
| Separate worktree | Correct checkout and distinct index, including when `.git` is a file. |
| Edit, generation, rename, new file, or branch switch | Current-file verification when the conclusion depends on freshness. |
| Broad negative claim | Entire intended scope covered; ignored/large files handled when relevant. |
| Short/common or broad regex query | No claim of index selectivity; avoid inflating selective batches. |
| Blocked loopback/background/index writes or missing binary | Task continues with suitable fallback; no policy change or repeated setup attempts. |
| Higher-priority ripgrep rule | Conflict respected and reported when material; no false claim of forced tgrep. |
| Multiple existing workers | One startup owner; shared suitable server; no redundant index builds. |
| Unsupported Codex version/discovery failure | Compatibility limitation visible; no duplicate installation into shared directories. |

Compare representative outputs against a direct search under equivalent file-admission rules. Include no-match and error paths, filenames with spaces, Unicode, hidden files, and required size-policy exceptions. Keep correctness checks independent of exact wording or section headings.

## Performance

Use a representative large monolithic project, a smaller control project, and fixed tasks that require understanding cross-module behavior. Hold Codex version/model, machine, permissions, and source state constant. Alternate baseline and skill runs, repeat them, and record both median and variation.

Measure cold index cost separately from warm query cost. Record total task time, search calls, readiness calls, full scans, output volume, correctness, index size, and CPU/memory impact. Do not count an omitted file or stale negative as a performance win. Cache state, foreground workload, and generated files can change results.

Acceptance requires correct results and observed useful tgrep selection, plus an improvement in representative repeated-search tasks without excessive setup or output. If the evidence does not show a benefit, adjust the skill or narrow its recommended scope before rollout. Publish no fixed speedup until measured.
