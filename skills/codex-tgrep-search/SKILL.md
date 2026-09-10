---
name: codex-tgrep-search
description: Use Microsoft tgrep for broad or repeated local repository text searches while implementing, debugging, or reviewing code, especially in large monolithic codebases. Reuse indexes, narrow candidate files, and verify freshness before decisive conclusions.
metadata:
  version: "0.1.0-draft"
  tgrep-version: "1.0.5"
---

# Efficient repository search with tgrep

Reduce repository scans, shell round trips, and irrelevant output without losing current-file correctness. Apply this workflow when a coding task requires broad or repeated text search; it is not limited to requests that explicitly mention search or tgrep.

## Choose scope before paying for setup

- Read a known file directly. For a narrow one-off lookup without a suitable index, use a scoped direct search or available filename tools; do not build an index merely to enumerate a few files.
- For broad discovery in a large source tree, prefer tgrep when available and compatible. Reuse a suitable server or disk index before considering a full scan.
- Use available semantic tools for symbol identity, references, or types. Text matches identify candidates, not a semantic call graph. Only editor tools can see unsaved buffers.
- If the executable is unavailable or incompatible, use an available alternative such as ripgrep. If local TCP, background execution, or index writes are unavailable, a suitable completed disk index can still serve exploration over unchanged files; otherwise use a scoped `--no-index` scan. Explain a material limitation once and continue the user's task. Do not install software or alter permissions during an ordinary search.

## Establish one search context per checkout

1. Resolve the actual checkout/worktree root from the task's working directory, using `git -C '<working-directory>' rev-parse --show-toplevel` when appropriate. A worktree can have a `.git` file, not a directory. Plain source folders are valid too. Search linked external sources only when the requested scope includes them.
2. Use the executable path supplied by the installed Codex instructions. If absent, resolve tgrep in the current environment. Once per executable/session, check its version; these instructions target 1.0.5. Inspect local help for a different version before relying on unfamiliar behavior.
3. Set the working directory explicitly on every shell tool call. Variables and directory changes need not persist between calls. Remember root, executable, index path, admission options, and readiness in the task context rather than assuming persistent shell state.
4. Keep a separate index for each distinct checkout/worktree. In 1.0.5 the default is `<search-root>/.tgrep`; searching a subdirectory does not find an ancestor index. Keep directory searches rooted at `.` and narrow with `-g 'src/**'` or `-t`. Do not store a shared index in Git's common directory.

The examples below use `tgrep` as shorthand for the resolved executable. With an absolute Windows path use `& '<resolved-tgrep-path>' ...`. The supplied setup does not add tgrep to PATH.

## Reuse readiness; do not check before every query

At the first broad search for a root/session, run `tgrep status .` with the chosen index options. Read the output: exit success can mean no index/server, and `Indexing: complete` means initial build complete, not up-to-date. Disk-only status does not certify build completion; if completion is unknown, use a direct scan for decisive results or resume a build when justified.

| Situation | Action |
| --- | --- |
| Suitable live server | Reuse it; do not rebuild or start another. |
| Complete disk index and unchanged relevant files | Reuse it for exploration; it cannot discover later changes. |
| No usable index and repeated broad searches expected | Start one server if the task environment permits local index writes/background execution. `serve` builds an index itself; do not run `index` first by habit. |
| Immediate answer needed while indexing | Use a narrowly scoped `--no-index` search or read likely files; do not repeatedly query an empty index. |
| Background process cannot persist | A completed `index` can serve repeated searches over unchanged files; use direct scans for freshness. |

For a first Windows startup or process/readiness failure, read [Windows execution](references/windows.md). Do not load that reference for every search. Avoid tight status polling, repeated installation checks, and whole-tree file counts just to choose a search strategy. A first build serves empty results until publication; a resumed build can be partial.

Keep `.tgrep` out of commits using the project's exclusion mechanism. Starting a server writes a local index and consumes resources. Reuse existing admission options; do not silently expand them. Do not terminate an existing server used by another task. If several workers already participate in the user's task, share the root/executable/options and coordinate one startup owner. This skill does not itself require delegation.

## Find candidates, then inspect the relevant code

Start with distinctive identifiers or strings and a likely component. Expand outward when evidence does not locate the implementation; do not assume a module-local search covers cross-cutting behavior in a monolith.

```text
tgrep -l -F -g 'src/**' -- 'OrderService' .
tgrep -n -H --color never -F -C 2 -- 'OrderService' 'src/Orders/OrderService.cs'
```

Use `-l` for broad candidate discovery. Then inspect the current relevant files with small context. Prefer plain paths/line numbers (`-H -n --color never`) for model reading; reserve `--json` for a parser that needs structured records. Excessive output can cost more than the search saves.

Batch a few related, selective literals when the same candidate-file set is useful:

```text
tgrep -l -F -g 'src/**' -e 'OrderService' -e 'OrderRepository' -- .
```

Patterns in this form are ORed. With `-e`, positional arguments are paths. Without `-e`/`-f`, use `tgrep <flags> -- <pattern> <root>`; put all flags before `--`, including when searching a word such as `index` or `serve`.

Do not combine a selective query with a common, empty, very short, or unindexable alternative: it can make every file a candidate. Avoid huge pattern batches. When independent results are required, batch a few independent commands in one tool call if supported, keeping their outputs/exit codes distinguishable. Avoid launching many concurrent full scans or index builds; they compete for disk and CPU.

For filenames, use `tgrep --files -g 'src/**' -t cs .` when its snapshot is suitable. In 1.0.5 the server still sends its full filename inventory before client filtering, so avoid repeated filename inventories even with a narrow glob. Retain useful paths and query findings in the task context instead of repeating searches after every edit. Scope first; `-m` limits matches per file, not total output, and truncated results do not prove completeness.

## Verify only the freshness the conclusion requires

Use a scoped direct scan after edits, generation, branch changes, or watcher problems when the answer depends on current saved content:

```text
tgrep --no-index -n -H --color never -F -g 'src/**' -- 'OldSettingName' .
```

Verify a negative indexed result before concluding that code or a string is absent. For an exhaustive repository-wide claim, cover the entire intended scope; a narrow validation cannot prove global absence. Read current candidate files before editing or making a final claim about their contents. Do not repeat every successful exploratory search as a full scan.

A running watcher is asynchronous and can miss events. `--files` is an index snapshot too. `--no-index` reads saved files but still applies ignore, hidden, binary, and size rules (64 MiB default); it cannot see unsaved buffers or excluded files. It is not an atomic snapshot. Rebuilding a disk index does not update a running server.

For hidden/ignored/large files, traversal flags, custom indexes, encoding, or structured output, read the relevant section of [Search details](references/search-details.md). In particular, `--follow`, `--one-file-system`, and `--ignore-file` require `--no-index` to take effect.

## Interpret evidence and finish the coding task

Capture stdout, stderr, and exit code together. `0` means a match, `1` means no match in the searched scope, and `2` means error (possibly with partial results). With `-q`, a match can mask another error. In PowerShell capture `$LASTEXITCODE` immediately when needed. Never hide missing-index warnings and then claim indexed performance.

Do not report setup success or a speedup based only on installed files, a process ID, or status success. Use search results to complete the user's actual coding task; mention tgrep limitations only when they affect the answer. Preserve user intent and higher-priority instructions.

## Provenance

Adapted from [Microsoft's tgrep agent guide](https://github.com/microsoft/tgrep/blob/v1.0.5/AGENTS.md) and [version 1.0.5](https://github.com/microsoft/tgrep/tree/v1.0.5). Attribution is installed beside this skill as `THIRD_PARTY_NOTICES.md` and is also available at the source repository root. Ordinary searches require no upstream documentation lookup.
