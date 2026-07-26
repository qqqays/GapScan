[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$CoordinatorHandle,

    [string]$Worktree = "active"
)

$ErrorActionPreference = "Stop"

$spec = @"
You are the coordinator for the native Orca prime-checker demo in $Worktree.
Use Orca orchestration as the source of truth; do not implement the workflow in
an external PowerShell loop.

Goal:
Run a small prime-checker workflow and demonstrate a real review feedback loop.
The first kilo review must reject once because the CLI output is not readable or
attractive enough; pi must repair the presentation, rerun verification, and kilo
must review again and approve only after the repair evidence exists.

Native coordinator procedure:
1. Read `orca orchestration task-list --ready --json` and the worktree files.
2. Create explicit tasks with `orca orchestration task-create`. Keep the first
   dependency chain shallow (plan -> implement -> verify -> review).
3. Create or use worker terminals with `orca terminal create`, inspect them with
   `orca terminal list`, and wait for readiness with `orca terminal wait`.
4. Dispatch each ready task with `orca orchestration dispatch --inject`.
5. Wait using `orca orchestration check --wait --types
   worker_done,escalation,decision_gate --timeout-ms 900000 --json`.
   A timeout is only a checkpoint; inspect task and terminal state and continue.
6. After the first kilo review returns REJECTED for presentation quality, create
   a new repair task depending on that review, then create verify-2 and review-2
   tasks depending on repair/verify-2. Do not mark the parent task complete yet.
7. Dispatch the next ready tasks. If a worker fails, inspect dispatch-show and
   retry with a fresh dispatch context; stop after the runtime circuit breaker.
8. Create a final hermes report task only after review-2 is APPROVED. The report
   must record every task ID, both review outcomes, verification commands and
   output, changed files, and progress.md evidence.

Acceptance evidence required before completing this parent task:
- explicit plan, implement, verify-1, review-1, repair, verify-2, review-2,
  and report task records;
- review-1 message contains REJECTED and a presentation/readability reason;
- repair message identifies the CLI presentation change;
- verify-2 contains a real passing command result;
- review-2 contains APPROVED after verify-2;
- hermes updates progress.md and reports SUCCESS.

Restrictions: do not push, delete files, modify production configuration, or
send external notifications. Send worker_done exactly once only after all
acceptance evidence is present, including taskId and dispatchId.
"@

function Invoke-OrcaJson {
    param([string[]]$Arguments)
    $raw = & orca @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "orca $($Arguments -join ' ') failed with exit code $LASTEXITCODE"
    }
    return ($raw | ConvertFrom-Json)
}

Write-Host "Creating native Orca coordinator task..." -ForegroundColor Cyan
$created = Invoke-OrcaJson @(
    "orchestration", "task-create",
    "--task-title", "Native Prime Review Loop",
    "--display-name", "Native prime coordinator",
    "--spec", $spec,
    "--json"
)

$taskId = $created.result.task.id
if ([string]::IsNullOrWhiteSpace($taskId)) {
    throw "Orca did not return a task ID"
}

$dispatch = Invoke-OrcaJson @(
    "orchestration", "dispatch",
    "--task", $taskId,
    "--to", $CoordinatorHandle,
    "--inject",
    "--json"
)

Write-Host "Native coordinator dispatched." -ForegroundColor Green
Write-Host "Task ID: $taskId"
Write-Host "Dispatch ID: $($dispatch.result.dispatch.id)"
Write-Host ""
Write-Host "Monitor with:"
Write-Host "  orca orchestration task-list --ready --json"
Write-Host "  orca orchestration check --wait --types `"worker_done,escalation,decision_gate` --timeout-ms 900000 --json"
Write-Host "  orca orchestration dispatch-show --task $taskId --json"
