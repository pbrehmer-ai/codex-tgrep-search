# Search details

Read only the section needed for the current query. These semantics target Microsoft tgrep 1.0.5.

## Index membership and traversal

- Default size limit: 64 MiB. A directly named file bypasses the inherited size cap, but an explicitly supplied cap still applies. `--no-max-filesize` removes the cap when the task requires it.
- `--hidden`, `--no-ignore`/`-u` variants, `--text`, `--binary`, explicit encoding, and naming a single file bypass the index. Use them when the requested scope needs them, and expect scanning cost.
- `--follow`, `--one-file-system`, and `--ignore-file` are accepted but ignored on indexed searches. Add `--no-index` when they must apply.
- `--files` uses the server/disk snapshot too. Add `--no-index` for a current list of eligible filenames.
- Keep root, `--index-path`, file-size policy, and `--no-require-git` consistent between index, server, and searches.
- `--exclude` applies to `index`/`serve`, not search. Preserve it and indexing `--no-ignore` between index and server: a changed server admission policy can remove files from an index.
- Outside a Git checkout, `.gitignore` is not applied by default. Use `--no-require-git` consistently when those ignore rules are intended.

An empty result covers only eligible files and the selected patterns/scope. For a task about ignored output, generated code, or large files, state and cover the relevant scope rather than dropping exclusions silently. Avoid broad `-uuu` on a monolith merely to increase confidence.

## Freshness and server health

Initial build completion is not freshness. Existing-index startup reconciliation happens in the background; a live index may lag a write or miss a watcher notification. Polling cadence is not a hard freshness guarantee. `--no-watch` disables subsequent automatic refresh.

Prefer scoped `--no-index` validation when current contents matter. Repeated full-tree rescans erase the benefit of indexed discovery, but a narrow search cannot prove a repository-wide absence. Choose the scope from the claim, including relevant linked source roots.

Only one server should own an index. Reuse it when options and environment fit. If another task wins a startup race, inspect status and reuse its suitable server; do not delete lock/discovery files or start another index build. Indexing independently while a server runs does not refresh that server.

## Pattern and output choices

- `-F` avoids regex work and escaping mistakes for literal identifiers. `-e` batches alternatives with OR semantics; it does not require every pattern to occur. Empty/short/common alternatives can defeat selectivity. Do not batch unrelated questions merely to reduce command count.
- Regexes without useful literal trigrams can approach a full scan. Prefer a known selective anchor and inspect nearby code when that answers the question, without replacing required regex semantics.
- `-l` stops content output after identifying candidate files; it is not a count. `-m` caps matches per file. A tool output limit can truncate a repository-wide result set independently.
- Use `--json` when another tool must parse records, not by default for reading code. It emits newline-delimited `begin`, `match`, `context`, `end`, and `summary` records. Invalid UTF-8 is repaired into `lines.text`; unlike ripgrep it does not emit the original invalid line as base64 `lines.bytes`.
- Use a byte-preserving alternative when exact original bytes matter. `--vimgrep` is useful for consumers that require file/line/column records.
- `-q` is suitable for a positive existence check; code `0` can mask an error elsewhere. Do not use it to prove an error-free exhaustive scan.
- Unsupported options are errors; for example, compressed-file `--search-zip` is unsupported. Some accepted compatibility flags have no effect. Consult the pinned upstream README only when an option is not covered here.

## Sources

- [Agent guide](https://github.com/microsoft/tgrep/blob/v1.0.5/AGENTS.md)
- [CLI and file admission](https://github.com/microsoft/tgrep/blob/v1.0.5/README.md)
- [Query planning](https://github.com/microsoft/tgrep/blob/v1.0.5/tgrep-core/src/query.rs)
