# tgrep Search for Codex

Help Codex navigate large monolithic codebases with fewer full-tree scans, fewer repeated tool calls, and more useful search output.

This repository packages [Microsoft tgrep](https://github.com/microsoft/tgrep) as a Codex skill, a short global search preference, and a Windows installer. The workflow reuses indexes and servers, groups related selective searches, and reads current candidate files before acting on them.

**Status: initial draft for review.** The files have been authored and statically reviewed. Installation, automatic skill activation, search correctness in Codex, and performance measurements are pending. No measured Codex speedup or guaranteed tool selection is claimed.

## Quick start

Initial target: **local Codex on Windows x64 or ARM64**, **PowerShell 5.1+**, with shell access. The source-reviewed Codex baseline is **0.153.4**; the tgrep release is pinned to **1.0.5**. Other Codex versions need discovery validation. WSL, remote hosts, and cloud execution need separate setup.

### 1. Download this repository

Clone it or use **Code → Download ZIP** and extract the archive. This repository is private; your GitHub account must have access.

```powershell
git clone https://github.com/pbrehmer-ai/codex-tgrep-search.git
Set-Location -LiteralPath '.\codex-tgrep-search'
```

### 2. Run one setup command

Review [what setup changes](#what-setup-changes) and [the installer](scripts/Install.ps1), then during the pilot run:

```powershell
.\scripts\Install.ps1
```

Setup installs a pinned Microsoft binary, the skill, and a marked section in the effective global Codex instruction file. It records an absolute executable path, so no PATH edit is needed. Existing unrelated instructions are preserved and replaced files are backed up.

If your company blocks unsigned scripts or direct downloads, follow [manual setup](docs/manual-setup.md) or use an IT-distributed copy. Preserve your existing execution and security policies. A `-WhatIf` preview is available for the later validation stage.

### 3. Start a fresh Codex task

Restart Codex after setup so global instructions are reloaded. Open your actual source checkout or worktree and ask for normal work, for example:

> Trace how an order moves from the API handler to persistence, identify the relevant implementation files, and explain where retries are applied.

The global instruction directs Codex to the skill when repository text searches are appropriate. You should see skill use and tgrep shell calls in the task. For explicit invocation, use `$codex-tgrep-search`. Automatic selection remains enabled, but user/project/host instructions and tool availability can affect which tool runs.

## What setup changes

| Location | Purpose |
| --- | --- |
| `%LOCALAPPDATA%\Programs\codex-tgrep\1.0.5\tgrep.exe` | Default binary, downloaded from Microsoft and checked against a pinned SHA-256 digest. |
| `$CODEX_HOME\skills\codex-tgrep-search\` | Skill, Codex metadata, focused references, and attribution; default home is `%USERPROFILE%\.codex`. |
| Effective global `AGENTS.override.md` or `AGENTS.md` in Codex home | A marked preference with absolute skill and executable paths. |
| `%LOCALAPPDATA%\codex-tgrep-search\backups\…` | Original-file backups and a recovery manifest. |
| A unique `%TEMP%\codex-tgrep-search-…` folder | Retained download/extraction staging for review and later cleanup. |

Setup does not modify PATH, Codex `config.toml`, sandbox settings, Copilot instructions, or project files. It does not execute tgrep, build indexes, or start servers. Later searches may create a local `.tgrep` index when the task environment allows it; keep those files out of commits.

An existing executable can be selected with `-TgrepPath 'C:\path\to\tgrep.exe'`. Setup then neither downloads nor replaces that executable; it only records the path. Its version and behavior must be verified separately. See [manual setup and reuse](docs/manual-setup.md).

## Why this helps large codebases

- **Reuse expensive work.** Check setup once per checkout/task and reuse the same live server or suitable disk index.
- **Search selectively.** Start with distinctive identifiers and likely components, then expand scope when needed.
- **Reduce tool overhead.** Combine a few related literal queries and remember discovered paths.
- **Spend context on relevant code.** Discover candidate filenames first, then read small current excerpts.
- **Keep conclusions current.** Validate decisive absences and post-edit checks with the appropriate direct scan instead of trusting a stale index.

The skill preserves native tools for semantic questions and direct reads for known files. It does not make every task faster. Cold indexing has a cost, and broad result delivery can dominate search time. Microsoft's published benchmarks measure search with an already built index, not complete Codex tasks. [Design and evidence](docs/design.md) explains the tradeoffs.

## Read more

| Purpose | File |
| --- | --- |
| Exact instructions Codex follows | [SKILL.md](skills/codex-tgrep-search/SKILL.md) |
| Always-available preference template | [Codex instruction](instructions/codex-tgrep.md) |
| Manual setup, reuse, updates, recovery, and removal | [Manual setup](docs/manual-setup.md) |
| Codex compatibility and technical choices | [Design and evidence](docs/design.md) |
| Employee rollout | [Team rollout](docs/team-rollout.md) |
| What must be tested before rollout | [Validation plan](docs/validation-plan.md) |

This is an independent Codex integration based on Microsoft and OpenAI documentation. It is not an official Microsoft or OpenAI extension. [Third-party notices](THIRD_PARTY_NOTICES.md) cover adapted upstream material.
