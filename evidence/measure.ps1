param(
    [string]$SessionRoot = (Join-Path $env:USERPROFILE '.codex/sessions')
)

$ErrorActionPreference = 'Stop'
$encoding = [Text.UTF8Encoding]::new($false)

function Read-Run {
    param([string]$Name)

    $directory = Join-Path $PSScriptRoot $Name
    $events = @(Get-Content -LiteralPath (Join-Path $directory 'events.jsonl') |
        ForEach-Object { ConvertFrom-Json -InputObject $_ })
    $id = ($events | Where-Object type -eq 'thread.started').thread_id
    $turns = @($events | Where-Object type -eq 'turn.completed')
    if ($turns.Count -ne 1 -or -not $id) { throw "Unexpected turn count or missing thread ID for $Name" }

    $promptPath = Join-Path $directory 'prompt.txt'
    $prompt = [IO.File]::ReadAllText($promptPath)
    $process = Get-Content -LiteralPath (Join-Path $directory 'process.json') -Raw | ConvertFrom-Json
    $tokensPath = Join-Path $directory 'token-usage.jsonl'
    $promptRecordPath = Join-Path $directory 'model-prompt.jsonl'
    $contextPath = Join-Path $directory 'run-context.json'
    $rollout = Get-ChildItem -LiteralPath $SessionRoot -File -Recurse -Filter "*$id.jsonl" |
        Select-Object -First 1

    if ($rollout) {
        $tokenLines = [Collections.Generic.List[string]]::new()
        $promptLines = [Collections.Generic.List[string]]::new()
        $context = $null
        foreach ($line in [IO.File]::ReadLines($rollout.FullName)) {
            $record = ConvertFrom-Json -InputObject $line
            if ($record.type -eq 'token_usage_record') {
                $tokenLines.Add($line)
            }
            if ($record.type -eq 'turn_context') {
                $context = $record.payload | Select-Object model, effort, cwd, approval_policy, sandbox_policy
            }
            if ($record.type -eq 'response_item' -and $record.payload.role -eq 'user' -and
                @($record.payload.content | Where-Object { $_.text -ceq $prompt }).Count -gt 0) {
                $promptLines.Add($line)
            }
        }
        if (-not $context -or $promptLines.Count -ne 1 -or $tokenLines.Count -eq 0) {
            throw "Missing rollout evidence for $Name"
        }
        [IO.File]::WriteAllLines($tokensPath, $tokenLines, $encoding)
        [IO.File]::WriteAllLines($promptRecordPath, $promptLines, $encoding)
        $context | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 -LiteralPath $contextPath
    }

    $recordedPrompt = Get-Content -LiteralPath $promptRecordPath -Raw | ConvertFrom-Json
    if ($recordedPrompt.payload.role -ne 'user' -or
        $recordedPrompt.payload.content.Count -ne 1 -or
        $recordedPrompt.payload.content[0].text -cne $prompt) {
        throw "Model prompt differs from captured standard input for $Name"
    }
    $context = Get-Content -LiteralPath $contextPath -Raw | ConvertFrom-Json
    $tokenRecords = @(Get-Content -LiteralPath $tokensPath |
        ForEach-Object { ConvertFrom-Json -InputObject $_ })
    $usage = $turns[0].usage
    foreach ($key in $usage.PSObject.Properties.Name) {
        if ($tokenRecords[-1].payload.turn_token_usage.$key -ne $usage.$key) {
            throw "Rollout and CLI totals disagree for $Name on $key"
        }
    }

    $items = @($events | Where-Object type -eq 'item.completed' | ForEach-Object { $_.item })
    $terminal = @($items | Where-Object type -eq 'command_execution')
    $files = @($items | Where-Object type -eq 'file_change')
    [ordered]@{
        thread_id = $id
        model = $context.model
        reasoning_effort = $context.effort
        sandbox = $context.sandbox_policy.type
        prompt_sha256 = (Get-FileHash -LiteralPath $promptPath).Hash
        cli_exit_code = $process.exit_code
        elapsed_seconds = [Math]::Round(
            ([DateTimeOffset]$process.ended_utc - [DateTimeOffset]$process.started_utc).TotalSeconds, 3)
        cli_turns = $turns.Count
        model_responses_with_usage = @($tokenRecords.payload.response_id | Sort-Object -Unique).Count
        cli_completed_shell_calls = $terminal.Count
        cli_nonzero_shell_calls = @($terminal | Where-Object { $_.exit_code -ne 0 }).Count
        cli_completed_file_edits = $files.Count
        cli_completed_mcp_calls = @($items | Where-Object type -eq 'mcp_tool_call').Count
        input_tokens = $usage.input_tokens
        cached_input_tokens = $usage.cached_input_tokens
        uncached_input_tokens = $usage.input_tokens - $usage.cached_input_tokens
        cache_write_input_tokens = $usage.cache_write_input_tokens
        output_tokens = $usage.output_tokens
        reasoning_output_tokens = $usage.reasoning_output_tokens
        total_tokens = $tokenRecords[-1].payload.turn_token_usage.total_tokens
        cost = $null
    }
}

$comparison = [ordered]@{ a = (Read-Run 'a'); b = (Read-Run 'b') }
foreach ($field in 'model', 'reasoning_effort', 'sandbox', 'prompt_sha256') {
    if ($comparison.a[$field] -cne $comparison.b[$field]) { throw "A and B disagree on $field" }
}
$comparison | ConvertTo-Json -Depth 6 |
    Set-Content -Encoding utf8 -LiteralPath (Join-Path $PSScriptRoot 'measurements.json')
$comparison | ConvertTo-Json -Depth 6
