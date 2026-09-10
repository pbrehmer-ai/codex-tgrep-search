# Manual setup, updates, and removal

Use this path when company policy prevents running the installer, when IT already supplies tgrep, or when inspecting each change. These procedures have not been executed for this initial draft.

## Prerequisites and scope

The pilot targets local Windows Codex, with the 0.153.4 loader reviewed for compatibility. Use PowerShell 5.1+ and a Windows x64 or ARM64 tgrep executable. Windows, WSL, remote, and cloud task environments have separate files and processes.

Resolve Codex home from the environment used to launch Codex: `$env:CODEX_HOME` when set, otherwise `$env:USERPROFILE\.codex`. Use an absolute path for a custom home. The default skill destination is `<CodexHome>\skills\codex-tgrep-search`. This is a deprecated compatibility location retained by the reviewed Codex version; see [design](design.md). Do not also install a duplicate in a shared `.agents/skills` directory.

## 1. Provide tgrep 1.0.5

Download the archive matching the **Windows operating system architecture** from [Microsoft's v1.0.5 release](https://github.com/microsoft/tgrep/releases/tag/v1.0.5), or obtain the same reviewed file through IT.

| Architecture | Archive | SHA-256 |
| --- | --- | --- |
| x64 | `tgrep-v1.0.5-x86_64-pc-windows-msvc.zip` | `5b6ba08ffddb5bc1b436c5c83b4f0c9e66c70a006b3853ed57daf51e7a75986c` |
| ARM64 | `tgrep-v1.0.5-aarch64-pc-windows-msvc.zip` | `f49b68f97810530688a8fe71282dfc384ed4ff99ffe7a8a769e43e68a7c633fe` |

Check the downloaded archive with `Get-FileHash -Algorithm SHA256 -LiteralPath '<archive-path>'`. Extract it into a new temporary folder and copy the root `tgrep.exe` to `%LOCALAPPDATA%\Programs\codex-tgrep\1.0.5\tgrep.exe`. Retain [third-party notices](../THIRD_PARTY_NOTICES.md) with the installed package. Do not replace unrelated executables or existing files without preserving their originals.

If a suitable executable already exists, including the one installed for Copilot, record that absolute path instead. The setup alternative is:

```powershell
.\scripts\Install.ps1 -TgrepPath "$env:LOCALAPPDATA\Programs\copilot-tgrep\1.0.5\tgrep.exe"
```

`-TgrepPath` checks that the file exists. It does not execute, hash, or validate the binary's version. Confirm the supplied executable and its ownership/version in the later pilot. This avoids silently changing another product's executable. The default installer always downloads and verifies its own pinned archive; it does not discover and reuse arbitrary PATH entries.

## 2. Install the skill folder

Copy the complete `skills/codex-tgrep-search` folder from this repository into `<CodexHome>/skills/`, preserving its name and structure. Then copy the repository-root `THIRD_PARTY_NOTICES.md` into that installed folder alongside `SKILL.md`.

The resulting folder contains:

```text
codex-tgrep-search/
  SKILL.md
  agents/openai.yaml
  references/windows.md
  references/search-details.md
  THIRD_PARTY_NOTICES.md
```

Keep a backup before replacing an existing skill. Do not install only `SKILL.md`: the referenced Windows and special-search guidance are part of this package.

## 3. Add the default instruction

In Codex home, inspect `AGENTS.override.md` and `AGENTS.md`. Codex 0.153.4 uses the first readable, nonempty file in that order after decoding UTF-8 and trimming whitespace. A whitespace-only override is skipped; a UTF-8 BOM-only override still wins.

Back up the effective file. Merge the complete marked block from [instructions/codex-tgrep.md](../instructions/codex-tgrep.md) into it, preserving unrelated text. If no effective file exists, create `AGENTS.md`; do not create a new override just for tgrep. Replace both placeholders in the copied block:

| Placeholder | Replacement |
| --- | --- |
| `__SKILL_PATH__` | Absolute path to the installed `SKILL.md`, using forward slashes. |
| `__TGREP_PATH__` | Absolute path to the intended `tgrep.exe`, using forward slashes. |

For example, an executable path could be `C:/Users/YourName/AppData/Local/Programs/codex-tgrep/1.0.5/tgrep.exe`. Preserve the code spans around each path. Do not leave placeholders in installed instructions.

Use UTF-8, with or without a BOM. The installer rejects invalid UTF-8, UTF-16/32, and NUL-containing global instruction files, including either candidate file it inspects. Make a deliberate backup and conversion before retrying; it will not silently convert them. Codex's own lossy UTF-8 decoding is not a reason to accept corrupted text.

If an override is later added or removed, re-evaluate which file is active. Re-running setup updates the currently effective file; an older block in an inactive base file is not automatically deleted. Project/host instructions can still affect search choices. The global rule is a preference, not an executable replacement for built-in search tools.

## 4. Reload and validate later

Restart Codex and start a fresh task in the intended checkout. Check skill discovery, effective instructions, and actual tgrep commands using the [validation plan](validation-plan.md). A skill read from the fallback absolute path can still guide a task, but record catalog discovery separately.

No PATH change is required. If invoking tgrep manually, use PowerShell's call operator with the absolute executable path. An installed file or a successful process start does not establish readiness, current results, or a speedup.

## Updates

Review a new repository revision before rerunning setup. It replaces its marked section and packaged files while preserving unrelated instruction text. It does not delete unexpected files already in the skill folder; review obsolete extras deliberately if a future package removes a file. Do not silently update the pinned tgrep version or reuse a different binary without compatibility validation.

## Recovery and removal

The installer writes `%LOCALAPPDATA%\codex-tgrep-search\backups\<run>\recovery.json`. Each changed file entry contains `Path`, `Existed`, and `Backup`; overwritten originals are stored as `file-NNN.before`. The record is saved before the destination write. Setup is not a transaction: partial changes may remain after a failure. A manifest status is not a runtime validation result.

Review entries from the affected run, newest changes first. Restore an original only after checking that it will not overwrite newer user edits. For a path that did not exist before setup, remove only that specific installed file if it is still owned by this package. Empty created directories and retained temporary downloads can be removed manually after confirming their exact paths. Recovery logs contain local paths; keep them local.

For normal removal, remove the marked `codex-tgrep-search` block from any global instruction file where setup placed it, preserve all other instructions, and remove this installed skill folder. Remove the default versioned executable only if no other task uses it. An executable supplied with `-TgrepPath` belongs to its original installation and should be left to that installation's owner.

No PATH rollback is needed. Do not terminate every tgrep process or delete project indexes indiscriminately. Identify the specific server/root before requested cleanup. Restart Codex after removing the global instruction and skill.
