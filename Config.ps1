#
# Powershell Desired Stage Config (DSC) Pull Server 
#
# Author:  Elliot Anderson <elliot.a@gmail.com>
# License: Apache 2.0
#

configuration DSCPullServer {

    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)] 
        [String]
        $ServerName = 'localhost'
    )

    Import-DSCResource -ModuleName xPSDesiredStateConfiguration

    Node $ServerName {
        
        WindowsFeature DSCServiceFeature {
            Ensure = 'Present'
            Name   = 'DSC-Service'
        }

        xDscWebService PSDSCPullServer {
            Ensure                  = "Present"
            EndpointName            = "PSDSCPullServer"
            Port                    = 8080
            State                   = "Started"
            PhysicalPath            = "$env:SystemDrive\inetpub\wwwroot\PSDSCPullServer"
            CertificateThumbPrint   = "AllowUnencryptedTraffic"
            ModulePath              = "$env:ProgramFiles\WindowsPowerShell\DscService\Modules"
            ConfigurationPath       = "$env:ProgramFiles\WindowsPowerShell\DscService\Configuration"
            DependsOn               = "[WindowsFeature]DSCServiceFeature"
        }

        xDscWebService PSDSCComplianceServer {
            Ensure                  = "Present"
            EndpointName            = "PSDSCComplianceServer"
            Port                    = 9080
            State                   = "Started"
            PhysicalPath            = "$env:SystemDrive\inetpub\wwwroot\PSDSCComplianceServer"
            CertificateThumbPrint   = "AllowUnencryptedTraffic"
            IsComplianceServer      = $true
            DependsOn               = "[WindowsFeature]DSCServiceFeature", "[xDSCWebService]PSDSCPullServer"
        }
    }
}

