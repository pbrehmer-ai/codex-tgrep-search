# Design and evidence

## Objective

Improve Codex's complete search workflow in a large monolithic source tree: fewer scans, repeated readiness checks, tool round trips, and irrelevant tokens, while preserving the scope and freshness needed for a correct coding result.

The implementation is a draft. Source review establishes intended behavior; it does not establish that a model invokes the skill reliably or that the workflow is faster in practice.

## Codex-specific choices

| Choice | Reason |
| --- | --- |
| A compact skill plus a short global instruction | Skills are loaded when selected; the global preference routes search needs arising inside ordinary coding tasks. |
| Name `codex-tgrep-search` | Avoids ambiguity with the separate Copilot skill. |
| Automatic invocation enabled | Users should not need to mention tgrep in each request. Explicit invocation remains available. |
| Absolute installed skill/executable paths in the global block | Helps when discovery is unavailable or the initial skill catalog is crowded, and avoids PATH precedence problems. |
| Codex-specific user skill directory | Keeps this pilot out of shared `.agents` directories scanned by other products. |
| Root-local, separate worktree indexes | Prevents accidentally searching the original checkout or another branch's index. |
| Task-context reuse and modest query batching | Reduces repeated shell setup and work on the same code. |
| Plain paths and line numbers by default | Avoids unnecessary JSON/detail output for code reading. |
| Direct validation when a conclusion needs it | Avoids silent stale-index absences without rescanning every exploratory query. |
| Explicit Windows execution reference | Keeps process and shell details out of the common search path. |

No search wrapper or MCP server is required: Codex already has a shell tool. No `rg` alias is replaced. A preference cannot override higher-priority host instructions or guarantee every tool choice. If a host mandates ripgrep, evaluate that conflict rather than claiming the skill supersedes it.

## Skill discovery compatibility

The current [OpenAI skills documentation](https://learn.chatgpt.com/docs/build-skills) describes `.agents/skills` for local discovery and recommends plugins for reusable distribution. The version-pinned [Codex 0.153.4 loader](https://github.com/openai/codex/blob/rust-v0.153.4/codex-rs/ext/skills/src/host_roots.rs#L95) also retains `$CODEX_HOME/skills` as a **deprecated backward-compatible user location**. The bundled skill installer in the inspected desktop installation uses that location.

This pilot deliberately uses the Codex-specific location. It is not presented as a permanent cross-version API. Test discovery when upgrading Codex. Do not install a second copy in `.agents/skills` to hide a discovery problem: duplicate names can appear, and other agents may discover that shared directory. The global block includes a direct path as a fallback when readable.

The source-reviewed local version was `codex-cli 0.153.4`; this is a compatibility baseline, not a claim that the installer has been executed with it. A Codex plugin is a possible later distribution package after behavioral validation. A plugin by itself does not establish that a local tgrep binary is installed or that the global search preference is active.

## Global instruction selection

[OpenAI documents global and project AGENTS guidance](https://learn.chatgpt.com/docs/agent-configuration/agents-md). The [0.153.4 global loader](https://github.com/openai/codex/blob/rust-v0.153.4/codex-rs/codex-home/src/instructions/mod.rs#L26) tries `AGENTS.override.md` then `AGENTS.md`, choosing the first readable, nonempty result after UTF-8 decoding and whitespace trimming.

Setup updates an existing effective override when necessary, and otherwise the base file. It never creates a new override simply to take precedence. A whitespace-only override is skipped; a UTF-8 BOM-only override is not whitespace to this loader. Existing global files must be valid UTF-8 for this installer; unsupported encodings require a deliberate manual conversion. Both candidate files are checked for concurrent changes before writes.

Project instructions can refine the global default, and instruction size limits can affect what reaches the model. Starting a new task/restarting Codex is part of setup verification. Source-level discovery support is not a substitute for observing actual tgrep tool calls.

## tgrep baseline

| Item | Pinned source |
| --- | --- |
| Release | [v1.0.5, published September 8, 2026](https://github.com/microsoft/tgrep/releases/tag/v1.0.5) |
| Agent guidance | [AGENTS.md at v1.0.5](https://github.com/microsoft/tgrep/blob/v1.0.5/AGENTS.md), introduced at commit `33675ce2342ad36bd080da3e1df91a863a22edbc` |
| Commands and admission | [README](https://github.com/microsoft/tgrep/blob/v1.0.5/README.md) |
| Index directory resolution | [builder.rs](https://github.com/microsoft/tgrep/blob/v1.0.5/tgrep-core/src/builder.rs) |
| Literal batching/selectivity | [query.rs](https://github.com/microsoft/tgrep/blob/v1.0.5/tgrep-core/src/query.rs) |
| Output and filename inventory | [search.rs](https://github.com/microsoft/tgrep/blob/v1.0.5/tgrep-cli/src/search.rs) |
| Readiness reporting | [status.rs](https://github.com/microsoft/tgrep/blob/v1.0.5/tgrep-cli/src/status.rs) |
| Server lifecycle | [serve.rs](https://github.com/microsoft/tgrep/blob/v1.0.5/tgrep-cli/src/serve.rs) |

The root used for a directory search determines its default index; there is no automatic parent-index lookup in 1.0.5. Status success can mean no index. Disk-only status does not certify completion, and a live server's initial completion does not certify freshness. These details are part of the skill's decision rules.

One less obvious large-repository cost: the server sends a whole filename inventory for `--files`, with glob/type filtering on the client. Narrowing printed filenames helps context, but does not remove that transfer. The skill therefore discourages repeated inventories.

## Performance interpretation

[Microsoft's benchmarks](https://github.com/microsoft/tgrep/blob/v1.0.5/BENCHMARKS.md) prebuild the index and include each new search client's startup and TCP round trip. Their results vary with repository, platform, query selectivity, and output volume. They are not Codex end-to-end benchmarks, and even the upstream table includes a case where ripgrep wins.

Our later evaluation must include cold setup, warm searches, irrelevant output, shell-call count, correctness, and total task time. A lower isolated query latency is not enough if the skill adds repeated status checks or makes the model inspect more text. See the [validation plan](validation-plan.md).
