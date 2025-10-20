# GitHub action script to publish to PowerShell gallery
$modulePath = Join-Path $PSScriptRoot "module"
Publish-Module -Path $modulePath -NuGetApiKey $env:APIKEY
