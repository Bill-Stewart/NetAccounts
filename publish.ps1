# GitHub action script to publish to PowerShell gallery
$newLocation = Set-Location (Split-Path $PSScriptRoot -Parent) -PassThru
Write-Host "Set location to $newLocation"
$modulePath = Join-Path $newLocation "module"
Write-Host "Module publish path is $modulePath"
Publish-Module -Path $modulePath -NuGetApiKey $env:APIKEY
