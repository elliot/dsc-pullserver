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
        Write-Host "Failed to download file ($Source)"
        exit
    }

    if ((Get-FileHash $Temp -Algorithm SHA1).Hash -ne $Checksum) {
        Remove-Item $Temp
        Write-Host "File integrity check failed ($Source)"
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

$Modules = @(
    @{
        File = 'https://gallery.technet.microsoft.com/xPSDesiredStateConfiguratio-417dc71d/file/131370/1/xPSDesiredStateConfiguration_3.0.3.4.zip';
        Hash = '73B9131D46AFBC864272CA425069EFB5EA1D4813';
    }
    @{
        File = 'https://gallery.technet.microsoft.com/xExchange-PowerShell-1dd18388/file/131350/2/xExchange_1.0.3.11.zip'
        Hash = 'B0048399CEA6A9304DFA94B48AB1185AE0E00B51';
    }
)

$Modules | % {
    Write-Host "Downloading module $($_.File)"

    DownloadAndExtract -Source $_.File -Target "$env:ProgramFiles\WindowsPowerShell\Modules" -Checksum $_.Hash
}

. .\Config.ps1

# Generate configuration
Write-Host "Generating state configuration"

DSCPullServer -ServerName $ServerName

# Apply configuration
Write-Host "Applying state configuration"

Start-DscConfiguration .\DSCPullServer –Wait

# Done
Write-Host "Complete"