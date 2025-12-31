param(
    [string]$ResourceGroup
)

$config = & $PSScriptRoot/../tools/GetClientConfigForAzure.ps1 -ResourceGroup $ResourceGroup
$configPath = Join-Path $PSScriptRoot "injected_client_config.json"
[System.IO.File]::WriteAllText($configPath, $config)
