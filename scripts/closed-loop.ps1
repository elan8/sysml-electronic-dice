#Requires -Version 7.0

param(
    [string]$Spec42 = 'spec42',
    [string]$Run42 = 'run42',
    [string]$Doc42 = 'doc42',
    [string]$Rustc = 'rustc',
    [Parameter(Mandatory)][string]$StdlibPath,
    [Parameter(Mandatory)][string]$DomainLibraryPath
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
$stdlib = (Resolve-Path -LiteralPath $StdlibPath).Path
$domain = (Resolve-Path -LiteralPath $DomainLibraryPath).Path
$project = Split-Path $PSScriptRoot -Parent
$fixture = Join-Path $project 'co-simulation'
$stamp = [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss-fff')
$run = Join-Path $project "generated/closed-loop-$stamp"
$model = Join-Path $run 'model'
$documents = Join-Path $model '80_documents'
$cache = Join-Path $project '.cache/doc42'

New-Item -ItemType Directory -Path $run | Out-Null
Copy-Item -LiteralPath (Join-Path $project 'model') -Destination $model -Recurse
Copy-Item -LiteralPath (Join-Path $fixture 'ClosedLoop.sysml') -Destination (Join-Path $model '60_systems/00_ElectronicDice')
Copy-Item -LiteralPath (Join-Path $fixture 'ClosedLoopReport.sysml') -Destination $documents
$guestSources = 'controller.rs', 'dice_logic.rs', 'play_monitor.rs', 'driver.json'
Copy-Item -LiteralPath ($guestSources | ForEach-Object { Join-Path $fixture $_ }) -Destination $run

& $Spec42 check $model --workspace-root $model --stdlib-path $stdlib --disable-kpar-library domain --disable-kpar-library method --library-path $domain --warnings-as-errors
if ($LASTEXITCODE -ne 0) { throw 'Spec42 closed-loop model validation failed.' }

& $Rustc --edition 2021 --target wasm32-unknown-unknown --crate-type cdylib -C opt-level=s -C panic=abort -o (Join-Path $run 'dice-controller.wasm') (Join-Path $run 'controller.rs')
if ($LASTEXITCODE -ne 0) { throw 'Building the controller for WebAssembly failed.' }

$rawVerdicts = Join-Path $run 'verdicts.json'
& $Run42 verify $model $domain --stdlib $stdlib --driver (Join-Path $run 'driver.json') --out $rawVerdicts --trace-dir (Join-Path $run 'traces') --trace-points 61
if ($LASTEXITCODE -ne 0) { throw "Run42 closed-loop verification failed. See $run." }

$records = @(Get-Content -LiteralPath $rawVerdicts -Raw | ConvertFrom-Json -AsHashtable)
$circuitCase = @($records | Where-Object { $_.case_name -eq 'DiceClosedLoop::playSixRolls' })
if ($circuitCase.Count -ne 1 -or $circuitCase[0].verdict -ne 'pass' -or $circuitCase[0].backend -ne 'wasm-modelica') {
    throw 'Expected a passing closed-loop case executed by the Wasm–Modelica backend.'
}
ConvertTo-Json -InputObject $circuitCase -Depth 10 |
    Set-Content (Join-Path $documents 'closed-loop-verdicts.json') -Encoding utf8NoBOM

& $Doc42 build $model --doc DiceClosedLoopDocuments::verificationReport --out $run --cache-dir $cache
if ($LASTEXITCODE -ne 0) { throw "Doc42 closed-loop report failed. The Run42 results are in $run." }
