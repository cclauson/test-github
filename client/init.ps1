param(
    [string]$ResourceGroup
)

../tools/GetClientConfigForAzure.ps1 -ResourceGroup $ResourceGroup > $PSScriptRoot/injected_client_config.json
