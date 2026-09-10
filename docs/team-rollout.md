# Team rollout

This repository is the initial authoring draft. No employee deployment, runtime validation, or benchmark has been performed.

## Recommended sequence

1. Review the skill, installer, instruction merge, Microsoft release digest, and intended local paths.
2. Run the [validation plan](validation-plan.md) in a disposable local profile and representative checkout.
3. Pin an accepted repository commit and tgrep version for a small pilot. Make that exact package accessible to pilot employees through the private repository or an approved internal channel.
4. Compare ordinary coding tasks with and without the skill, then revise only what observations justify.
5. Expand access and deployment after the pilot meets correctness and efficiency criteria.

Repository ownership does not grant employees access automatically. A team administrator can later distribute a reviewed archive or grant the appropriate access. Keep package distribution, executable availability, and model behavior as separate acceptance checks.

## What employees do

Download the reviewed package, run its setup once per Windows user/Codex profile, restart Codex, and open their source checkout. The README is the employee entry point. An explicit skill mention is useful for troubleshooting, but successful pilot tasks should also work without it.

The installer respects a custom `CODEX_HOME`. A separately launched CLI/profile, remote host, WSL instance, or cloud environment does not inherit this installation automatically. Confirm which environment actually runs the shell commands.

If central software distribution already supplies tgrep, use `-TgrepPath` with its absolute path and validate that version against the skill. This option does not hash or execute an existing binary. An IT-managed binary must not be overwritten by our default installer path.

## Maintenance

Keep one active Codex skill copy, separate from the Copilot integration. On updates, review the upstream release and AGENTS changes, executable hashes, Codex skill discovery, and the effective global instruction file. Re-run the appropriate compatibility checks before distributing a new revision. Repeated setup updates its marked block while retaining unrelated instructions.

The initial Codex-specific discovery path is deprecated but retained in the reviewed Codex version. Track that dependency explicitly. OpenAI's documented plugin distribution is a later packaging option once the local behavior is verified; it is not a reason to publish an untested plugin or broaden support claims now.

Do not promise a fixed multiplier, automatic selection in every task, or support for every Codex environment. Report the measured result for the tested repository, machine, model, permissions, and query/task set.
