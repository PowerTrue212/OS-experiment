$Host.UI.RawUI.WindowTitle = 'T4 Best-Fit verification'
Clear-Host
& wsl.exe -d ReductWSL --exec bash /mnt/d/OS/OS-experiment/lab2/docs/T4_best_fit_test_logs/run_t4_tests.sh 2> "$PSScriptRoot/wsl-stderr.log"
$testExitCode = $LASTEXITCODE
Set-Content -LiteralPath "$PSScriptRoot/terminal-exit-status.txt" -Value $testExitCode
if ($testExitCode -ne 0) {
    Write-Host "Test runner exited with code $testExitCode. Inspect logs." -ForegroundColor Red
}
