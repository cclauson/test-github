param(
    [string]$ResourceGroup
)

& $PSScriptRoot/../tools/GetClientConfigForAzure.ps1 -ResourceGroup $ResourceGroup > $PSScriptRoot/injected_client_config.json
