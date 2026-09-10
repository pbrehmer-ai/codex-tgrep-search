# Windows execution

Read when starting a server or troubleshooting executable discovery and process lifetime. Supported initial target: local Codex on Windows x64/ARM64 with PowerShell 5.1+, using tgrep 1.0.5. WSL, remote hosts, and cloud tasks require their own executable and setup; a Windows installation is not transferred there.

## Establish root and executable

Use the absolute executable path in the installed Codex instruction block. Set the shell tool's working-directory argument on every call, or include `Set-Location -LiteralPath` in the command. For example, substitute the resolved values below; these are placeholders, not literal paths:

```powershell
Set-Location -LiteralPath '<checkout-root>'
& '<resolved-tgrep-path>' --version
& '<resolved-tgrep-path>' status .
```

Do this readiness check once per root/session; do not copy it into every query. If no configured path exists, `Get-Command tgrep -CommandType Application -ErrorAction Stop` resolves PATH. A missing configured binary calls for a fallback or setup repair, not a download during the coding task.

## Start only when reuse will justify the work

After confirming no suitable server exists and index writes/background execution are allowed:

```powershell
Set-Location -LiteralPath '<checkout-root>'
$searchProcess = Start-Process -FilePath '<resolved-tgrep-path>' -ArgumentList @('serve', '.') -WorkingDirectory (Get-Location).Path -WindowStyle Hidden -PassThru
$searchProcess.Id
& '<resolved-tgrep-path>' status .
```

The example uses the default root-local index. Preserve any existing custom `--index-path` and admission options; `Start-Process` joins argument strings, so paths containing spaces need appropriate quoting. Do not copy the example unchanged for custom options.

Record the new process ID with its root for any later requested cleanup. A returned PID does not prove startup succeeded or that Codex's environment lets the process survive the tool call. When persistence is not yet established, check status once in a subsequent tool invocation after startup. A search may silently use an existing disk index after the server stops, so its success alone does not prove persistence. Thereafter recheck on relevant symptoms rather than before every query. Do not switch to a process watcher or scheduled task to keep it alive.

If background processes cannot persist, run a foreground `index .` only when repeated searches justify the build. Use the shell tool's ordinary running-session handle to await completion and keep the user informed; do not launch another build because the first call returned early. Never detach a long foreground build accidentally. An unfinished build cannot support exhaustive results.

## Shell and environment details

- Use literal PowerShell paths and single-quoted literal patterns; double a literal apostrophe inside a single-quoted string. Do not construct shell code by concatenating untrusted search text.
- Capture `$LASTEXITCODE` immediately after the native command if the tool wrapper does not preserve it. For several commands in one call, label/capture each result so no-match can be distinguished from a later command's success.
- Keep existing sandbox and approval settings. If loopback or index writes are blocked, a scoped direct scan may still work. Repeatedly asking for wider permissions is not a search optimization.
- A `.git` file in a worktree is valid. Root-local `.tgrep` must belong to that worktree, not to the original checkout.
- Do not reuse a server across Windows and WSL paths or different hosts. Executable, index, and process must belong to the environment running the search.
- Do not kill all `tgrep` processes. Cleanup, when requested, must identify the process and root owned by this task.
