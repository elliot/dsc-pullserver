#requires -RunAsAdministrator

#
# Powershell Desired Stage Config (DSC) Pull Server 
#
# Author:  Elliot Anderson <elliot.a@gmail.com>
# License: Apache 2.0
#

Param (
     [Parameter(Mandatory = $true, Position=0, HelpMessage="DSC Server Name")]
     [String] $ServerName
)

#region Helpers
function DownloadAndExtract
{
    param (
        $Source,
        $Target,
        $Checksum
    )

    $Temp = [System.IO.Path]::GetTempFileName().Replace('.tmp', '.zip')

    $Client = New-Object Net.WebClient
    $Client.DownloadFile($Source, $Temp)

    if (!(Test-Path $Temp)) {
        Write-Host -ForegroundColor Red "Failed to download file ($Source)"
        exit
    }

    if ((Get-FileHash $Temp -Algorithm SHA1).Hash -ne $Checksum) {
        Remove-Item $Temp
        Write-Host -ForegroundColor Red "File integrity check failed ($Source)"
        exit
    }

    if (!(Test-Path $Target)) {
        New-Item -ItemType Directory -Path $Dest
    }

    $Items = (New-Object -ComObject Shell.Application).Namespace($Temp).Items()
    $Shell = (New-Object -ComObject Shell.Application).Namespace($Target).CopyHere($Items, 16)

    Remove-Item $Temp
}
#endregion

# Begin Bootstrap
Write-Host "Starting bootstrap process"

Write-Host "Installing Windows Features"

# Enable Windows Features
Add-WindowsFeature Dsc-Service -IncludeManagementTools

# Enable WS Management listener
Enable-PSRemoting -Force

$PSModules = "$env:ProgramFiles\WindowsPowerShell\Modules"

$Modules = @(
    @{
        File = 'https://gallery.technet.microsoft.com/scriptcenter/DSC-Resource-Kit-All-c449312d/file/131371/2/DSC%20Resource%20Kit%20Wave%2010%2002182015.zip'
        Hash = '63F68C163C2B526A7A7429296C8EE0C502C3D38B';
    }
)

$Modules | % {
    Write-Host "Downloading module $($_.File)"

    DownloadAndExtract -Source $_.File -Target $PSModules -Checksum $_.Hash
}

# Fix the Resource Kit
Get-ChildItem "$PSModules\All Resources" | % {
    Move-Item $_.FullName $_.Parent.Parent.FullName
}

Remove-Item -Force "$PSModules\All Resources"

# Force a module cache reload
Get-DscResource | Out-Null

. .\Config.ps1

# Generate configuration
Write-Host "Generating state configuration"

DSCPullServer -ServerName $ServerName

# Apply configuration
Write-Host "Applying state configuration"

Start-DscConfiguration .\DSCPullServer –Wait

# Done
Write-Host "Complete"