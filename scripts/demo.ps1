param(
    [string]$Spec42 = 'spec42',
    [string]$Run42 = 'run42',
    [string]$Doc42 = 'doc42',
    [Parameter(Mandatory)][string]$StdlibPath,
    [Parameter(Mandatory)][string]$DomainLibraryPath
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
$stdlib = (Resolve-Path -LiteralPath $StdlibPath).Path
$domain = (Resolve-Path -LiteralPath $DomainLibraryPath).Path
$project = Split-Path $PSScriptRoot -Parent
$source = Join-Path $project 'model'
$stamp = [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss-fff')
$run = Join-Path $project "generated/$stamp"
$selected = Join-Path $run 'selected'
$comparison = Join-Path $run 'comparison'
$cache = Join-Path $project '.cache/doc42'
New-Item -ItemType Directory -Path $run | Out-Null
Copy-Item -LiteralPath $source -Destination $selected -Recurse
Copy-Item -LiteralPath $selected -Destination $comparison -Recurse

& $Spec42 check $selected --workspace-root $selected --stdlib-path $stdlib --disable-kpar-library domain --disable-kpar-library method --library-path $domain --warnings-as-errors
if ($LASTEXITCODE -ne 0) { throw 'Spec42 model validation failed.' }

# Change only the debounce parameter in the disposable comparison snapshot.
$controller = Join-Path $comparison '60_systems/RollController/system.sysml'
$modelText = [IO.File]::ReadAllText($controller)
$baseline = 'attribute debounce : TimeValue = 0.010 [s];'
if ([regex]::Matches($modelText, [regex]::Escape($baseline)).Count -ne 1) {
    throw 'Expected exactly one selected debounce parameter at 10 ms.'
}
[IO.File]::WriteAllText($controller, $modelText.Replace($baseline, 'attribute debounce : TimeValue = 0.003 [s];'))

$cases = @('DiceVerification::bouncingPress', 'DiceVerification::releaseAndRollAgain')
$fastVerdicts = Join-Path $comparison '80_documents/fast-verdicts.json'
& $Run42 verify $comparison $domain --stdlib $stdlib --out $fastVerdicts
if ($LASTEXITCODE -eq 0 -or !(Test-Path -LiteralPath $fastVerdicts)) {
    throw 'The 3 ms comparison did not produce the expected failing run.'
}
$fastRecords = @(Get-Content -LiteralPath $fastVerdicts -Raw | ConvertFrom-Json)
if ($fastRecords.Count -ne $cases.Count) { throw 'Unexpected comparison case count.' }
foreach ($case in $cases) {
    $record = @($fastRecords | Where-Object { $_.case_name -eq $case })
    if ($record.Count -ne 1 -or $record[0].verdict -ne 'fail') {
        throw "Expected a failed assertion for $case at 3 ms."
    }
}

$selectedVerdicts = Join-Path $selected '80_documents/verdicts.json'
& $Run42 verify $selected $domain --stdlib $stdlib --out $selectedVerdicts
if ($LASTEXITCODE -ne 0) { throw 'Run42 verification failed for the selected design.' }
$selectedRecords = @(Get-Content -LiteralPath $selectedVerdicts -Raw | ConvertFrom-Json)
if ($selectedRecords.Count -ne $cases.Count) { throw 'Unexpected selected case count.' }
foreach ($case in $cases) {
    $record = @($selectedRecords | Where-Object { $_.case_name -eq $case })
    if ($record.Count -ne 1 -or $record[0].verdict -ne 'pass') {
        throw "Expected a passing verdict for $case at 10 ms."
    }
}

Copy-Item -LiteralPath $fastVerdicts -Destination (Join-Path $selected '80_documents')
& $Doc42 build $selected --doc DiceDocuments::verificationReport --out $run --cache-dir $cache
if ($LASTEXITCODE -ne 0) { throw "Doc42 build failed. The Run42 results are in $run." }
