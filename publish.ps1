# GitHub action script to publish to PowerShell gallery
$modulePath = Join-Path $PSScriptRoot "../module"
Write-Host "Publish path: $modulePath"
Publish-Module -Path $modulePath -NuGetApiKey $env:APIKEY
