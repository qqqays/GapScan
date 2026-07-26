[CmdletBinding()]
param(
    [string]$Worktree = "active",
    [ValidateRange(1, 10)]
    [int]$MaxConcurrent = 3,
    [ValidateRange(1000, 60000)]
    [int]$PollIntervalMs = 5000
)

$goal = @"
Run the prime-checker teaching demo in examples/prime_checker.py.

Acceptance criteria:
- is_prime() correctly handles negative numbers, 0, 1, 2, primes, and composites.
- Focused tests pass.
- The command-line output clearly shows the input and a readable PRIME or NOT PRIME result.
- progress.md records the evidence and final status.

Required loop demonstration:
- The first kilo review MUST be REJECTED once, even if the prime algorithm is correct.
- The rejection reason must be presentation quality: ask pi to make the printed output more readable and attractive.
- pi must make that presentation repair, rerun the focused verification, and send it back to kilo.
- The second kilo review may PASS only after the repair evidence is present.

Restrictions: do not push, delete files, modify production configuration, or send external notifications.
"@

& "$PSScriptRoot\run-gapscan-loop.ps1" `
    -Goal $goal `
    -Worktree $Worktree `
    -MaxConcurrent $MaxConcurrent `
    -PollIntervalMs $PollIntervalMs

if ($LASTEXITCODE -ne 0) {
    throw "Prime loop demo failed with exit code $LASTEXITCODE"
}
