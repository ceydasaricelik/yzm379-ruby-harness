param(
    [Parameter(Mandatory)][string]$Executable,
    [Parameter(Mandatory)][string]$Workspace,
    [Parameter(Mandatory)][string]$Evidence,
    [string]$RubyBin,
    [string[]]$RunOptions = @()
)
$ErrorActionPreference = 'Stop'
$workspacePath = (Resolve-Path -LiteralPath $Workspace).Path
$evidencePath = (Resolve-Path -LiteralPath $Evidence).Path
$arguments = @(
    'exec', '--json', '--color', 'never', '--ignore-user-config', '--ignore-rules',
    '--skip-git-repo-check', '--sandbox', 'workspace-write', '-m', 'gpt-6.2-sol',
    '-c', 'model_reasoning_effort=medium', '-c', 'windows.sandbox=unelevated',
    '-c', 'project_root_markers=[]'
) + $RunOptions + @('-')
$configuration = [System.Diagnostics.ProcessStartInfo]::new()
$configuration.FileName = (Resolve-Path -LiteralPath $Executable).Path
$configuration.WorkingDirectory = $workspacePath
$configuration.UseShellExecute = $false
$configuration.CreateNoWindow = $true
$configuration.RedirectStandardInput = $true
$configuration.RedirectStandardOutput = $true
$configuration.RedirectStandardError = $true
$configuration.Environment['NoDefaultCurrentDirectoryInExePath'] = '1'
foreach ($name in @('CODEX_APP_RUNTIME_CLI_PATH', 'CODEX_APP_TOOLS_PIPE_PATH',
    'CODEX_WINDOWS_REGISTERED_CORE', 'CODEX_WINDOWS_SANDBOX_PACKAGE_FAMILY',
    'CODEX_SHELL', 'CODEX_SESSION_ID', 'CODEX_THREAD_ID', 'CODEX_TOOL_CALL_ID',
    'CODEX_TASK_WORKSPACE_VERIFYING_IDENTITY', 'CODEX_INTERNAL_ORIGINATOR_OVERRIDE')) {
    [void]$configuration.Environment.Remove($name)
}
if ($RubyBin) {
    [void]$configuration.Environment.Remove('GEM_HOME')
    [void]$configuration.Environment.Remove('GEM_PATH')
    $configuration.Environment['PATH'] = (Resolve-Path -LiteralPath $RubyBin).Path + ';' + $configuration.Environment['PATH']
}
foreach ($argument in $arguments) {
    $configuration.ArgumentList.Add($argument)
}
$arguments | ConvertTo-Json | Set-Content -Encoding utf8 (Join-Path $evidencePath 'arguments.json')
$processInfo = [ordered]@{
    started_utc = [DateTimeOffset]::UtcNow.ToString('o')
    working_directory = $workspacePath
    executable = $configuration.FileName
    ruby_bin = $RubyBin
}
$stdout = [IO.File]::Open((Join-Path $evidencePath 'events.jsonl'), 'Create', 'Write', 'Read')
$stderr = [IO.File]::Open((Join-Path $evidencePath 'stderr.log'), 'Create', 'Write', 'Read')
try {
    $process = [System.Diagnostics.Process]::Start($configuration)
    $stdoutCopy = $process.StandardOutput.BaseStream.CopyToAsync($stdout)
    $stderrCopy = $process.StandardError.BaseStream.CopyToAsync($stderr)
    $prompt = [IO.File]::ReadAllBytes((Join-Path $evidencePath 'prompt.txt'))
    $process.StandardInput.BaseStream.Write($prompt, 0, $prompt.Length)
    $process.StandardInput.Close()
    $process.WaitForExit()
    $processInfo.exit_code = $process.ExitCode
    [void]$stdoutCopy.GetAwaiter().GetResult()
    [void]$stderrCopy.GetAwaiter().GetResult()
} finally {
    $stdout.Dispose()
    $stderr.Dispose()
    $processInfo.ended_utc = [DateTimeOffset]::UtcNow.ToString('o')
    $processInfo | ConvertTo-Json | Set-Content -Encoding utf8 (Join-Path $evidencePath 'process.json')
}
