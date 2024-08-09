# **************************************************************************************
# Script:  bicep_install.ps1
# 
# Purpose: Ensures the latest version of bicep is installed.
#          Equivalent to az bicep upgrade but without the need for Azure CLI or Az CLI login.
#
# Usage:   ./bicep_install.ps1
# **************************************************************************************

Write-Output "*** bicep_install.ps1 script start ***";

$installPath = "$env:USERPROFILE\.bicep";
$exePath = "$installPath\bicep.exe";

# Determine system architecture
$architecture = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
Write-Output "System architecture: $architecture"

# Check if Bicep is already installed and get current version
if (Test-Path $exePath) {
    Write-Output("Bicep test path: $exePath");
    Start-Process -FilePath $exePath -ArgumentList '--version' -NoNewWindow -RedirectStandardOutput 'versionOutput.txt' -Wait
    $versionOutput = Get-Content 'versionOutput.txt'
    Remove-Item 'versionOutput.txt' -Force
    $currentVersion = $versionOutput -replace 'Bicep CLI version ([\d\.]+).*','$1'
    Write-Output "Current Bicep version: $currentVersion"
} else {
    Write-Output "Bicep is not installed."
    $currentVersion = $null
}

# Fetch the latest release version from GitHub
$latestRelease = Invoke-WebRequest -Uri "https://api.github.com/repos/Azure/bicep/releases/latest" -UseBasicParsing | ConvertFrom-Json
$latestVersion = $latestRelease.tag_name.Trim('v')
Write-Output "Latest available Bicep version: $latestVersion"

# Compare versions and download if there's a newer version
if ($currentVersion -ne $latestVersion) {
    Write-Output "Updating/installing to the latest Bicep version."
    $installDir = New-Item -ItemType Directory -Path $installPath -Force;
    $installDir.Attributes += 'Hidden';

    #https://github.com/Azure/bicep/releases/download/v0.29.47/bicep-setup-win-x64.exe
    #https://github.com/Azure/bicep/releases/download/v0.29.47/bicep-win-x64.exe

    $downloadUrl = $latestRelease.assets | Where-Object { $_.name -like "bicep-win-$architecture.exe" } | Select-Object -ExpandProperty browser_download_url
    Write-Output("downloadUrl: $downloadUrl");
    Invoke-WebRequest -Uri $downloadUrl -OutFile $exePath

    # Add bicep to PATH if not already present
    $currentPath = (Get-Item -Path "HKCU:\Environment").GetValue('Path', '', 'DoNotExpandEnvironmentNames')
    if (-not $currentPath.Contains("$installPath")) {
        setx PATH ($currentPath + ";$installPath")
        $env:path += ";$installPath"
    }
    
    Start-Process -FilePath $exePath -ArgumentList '--version' -NoNewWindow -RedirectStandardOutput 'newVersionOutput.txt' -Wait
    $newVersionOutput = Get-Content 'newVersionOutput.txt'
    Remove-Item 'newVersionOutput.txt' -Force
    $newVersion = $newVersionOutput -replace 'Bicep CLI version ([\d\.]+).*','$1'
    Write-Output "Installed/Updated Bicep version: $newVersion"
} else {
    Write-Output "No update needed. Bicep is up to date."
}

# Get the system PATH environment variable
$pathVariable = [Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [Environment]::GetEnvironmentVariable("PATH", "User")

# Split the PATH into an array of individual paths
$paths = $pathVariable -split ';'

# Filter paths that contain the keyword 'bicep', case-insensitive
$bicepPaths = $paths | Where-Object { $_ -like '*bicep*' }

# Output the filtered paths
if ($bicepPaths) {
    Write-Output "Directories containing 'bicep' in the PATH:"
    $bicepPaths | ForEach-Object { Write-Output $_ }
} else {
    Write-Output "No directories containing 'bicep' were found in the PATH."
}

Write-Output "`r`n*** bicep_install.ps1 script end ***"
