#Requires -Version 7.0
param(
    [string]$Run42 = 'run42',
    [string]$Spec42 = 'spec42',
    [string]$Rustc = 'rustc',
    [string]$Python = 'python',
    [Parameter(Mandatory)][string]$StdlibPath,
    [Parameter(Mandatory)][string]$DomainLibraryPath,
    [Parameter(Mandatory)][string]$LabWiredSystem
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
$stdlib = (Resolve-Path -LiteralPath $StdlibPath).Path
$domain = (Resolve-Path -LiteralPath $DomainLibraryPath).Path
$labwired = (Resolve-Path -LiteralPath $LabWiredSystem).Path
$project = Split-Path $PSScriptRoot -Parent
$fixture = Join-Path $project 'co-simulation/stm32'
$stamp = [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss-fff')
$run = Join-Path $project "generated/elf-comparison-$stamp"
$model = Join-Path $run 'model'
New-Item -ItemType Directory -Path $run | Out-Null
Copy-Item -LiteralPath (Join-Path $project 'model') -Destination $model -Recurse
Copy-Item -LiteralPath (Join-Path $fixture 'ElfPlay.sysml') -Destination (Join-Path $model '60_systems/00_ElectronicDice')
Copy-Item -LiteralPath (Join-Path $fixture 'f407.repl') -Destination $run

& $Spec42 check $model --workspace-root $model --stdlib-path $stdlib --disable-kpar-library domain --disable-kpar-library method --library-path $domain --warnings-as-errors
if ($LASTEXITCODE -ne 0) { throw 'Spec42 ELF fixture validation failed.' }

$linker = Join-Path $fixture 'firmware.ld'
$firmware = Join-Path $run 'dice.elf'
& $Rustc --edition 2021 --target thumbv7em-none-eabihf -C opt-level=2 -C panic=abort -C "link-arg=-T$linker" -o $firmware (Join-Path $fixture 'main.rs')
if ($LASTEXITCODE -ne 0) { throw 'Building the Cortex-M ELF failed.' }

foreach ($backend in 'labwired', 'renode') {
    $config = Get-Content -LiteralPath (Join-Path $fixture 'driver.json') -Raw | ConvertFrom-Json -AsHashtable
    $config.elf.backend = $backend
    $config.elf.system = if ($backend -eq 'labwired') { $labwired } else { 'f407.repl' }
    if ($backend -eq 'labwired') {
        $config.elf.tick_interval = 16
    }
    $driver = Join-Path $run "$backend.json"
    $config | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $driver -Encoding utf8NoBOM
    & $Run42 verify $model $domain --stdlib $stdlib --driver $driver --out (Join-Path $run "$backend-verdicts.json") --trace-dir (Join-Path $run $backend)
    if ($LASTEXITCODE -ne 0) { throw "Run42 verification failed for $backend. See $run." }
}
& $Python (Join-Path $fixture 'check_traces.py') $run
if ($LASTEXITCODE -ne 0) { throw "The ELF traces did not pass comparison. See $run." }
Write-Output $run
