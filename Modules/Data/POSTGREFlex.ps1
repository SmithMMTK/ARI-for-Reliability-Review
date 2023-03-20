<#
.Synopsis
Inventory for Azure Database for Postgre

.DESCRIPTION
This script consolidates information for all microsoft.dbforpostgresql/flexibleservers resource provider in $Resources variable. 
Excel Sheet Name: POSTGRE

.Link
https://github.com/microsoft/ARI/Modules/Data/POSTGRE.ps1

.COMPONENT
This powershell Module is part of Azure Resource Inventory (ARI)

.NOTES
Version: 2.2.2
First Release Date: 19th November, 2020
Authors: Claudio Merola and Renato Gregio 

#>

<######## Default Parameters. Don't modify this ########>

param($SCPath, $Sub, $Intag, $Resources, $Task , $File, $SmaResources, $TableStyle, $Unsupported)



If ($Task -eq 'Processing') {

    $POSTGRE = $Resources | Where-Object { $_.TYPE -eq 'microsoft.dbforpostgresql/flexibleservers' }

    if($POSTGRE)
        {          
            $tmp = @()

            foreach ($1 in $POSTGRE) {
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.id -eq $1.subscriptionId }
                $data = $1.PROPERTIES
                $sku = $1.SKU


                # Load Get-Service Detail Module
                . ./Get-ServiceDetails.ps1    

                
                if ($data.highAvailability.mode -eq "ZoneRedundant") {
                    $HA = "1, 2, 3"
                    $jsonOutput = Get-ServiceDetails -Type 'AzurePostgreSQLFlex'  -Resilience 'Zonal'

                } 
                else 
                {
                    $HA = ""

                     # Check geoRedundantBackup from $data.backup that Enabled or Disabled then assign True / False to $geoBackup
                        if ($data.backup.geoRedundantBackup -eq "enabled") {                           
                            $jsonOutput = Get-ServiceDetails -Type 'AzurePostgreSQLFlex-Geo'  -Resilience 'Single'
                        } else {                           
                            $jsonOutput = Get-ServiceDetails -Type 'AzurePostgreSQLFlex'  -Resilience 'Single'
                        }                    
                }

                                    
                # Get RTO information from $jsonOutput field RTO
                $RTO = $jsonOutput | ConvertFrom-Json | Select-Object -ExpandProperty RTO

                # Get RPO information from $jsonOutput field RPO
                $RPO = $jsonOutput | ConvertFrom-Json | Select-Object -ExpandProperty RPO
                
                # Get SLA information from $jsonOutput field SLA
                $SLA = $jsonOutput | ConvertFrom-Json | Select-Object -ExpandProperty SLA

                # Set Type value for combine tab
                $azureServices = 'Azure Database for PostgreSQL Flex'

                if(!$data.privateEndpointConnections){$PVTENDP = $false}else{$PVTENDP = $data.privateEndpointConnections.Id.split("/")[8]}
                $Tags = if(![string]::IsNullOrEmpty($1.tags.psobject.properties)){$1.tags.psobject.properties}else{'0'}
                    foreach ($Tag in $Tags) {
                        $obj = @{
                            'ID'                        = $1.id;
                            'Subscription'              = $sub1.Name;
                            'Resource Group'            = $1.RESOURCEGROUP;
                            'Name'                      = $1.NAME;
                            'RTO'                           = [string]$RTO;
                            'RPO'                           = [string]$RPO;
                            'SLA'                           = [string]$SLA;
                            'Resource Name'              = $1.NAME;
                            'Azure Services'             = $azureServices;  
                            'Location'                  = $1.LOCATION;
                            'Zones'                     = $HA;
                            'SKU'                       = $sku.name;
                            'SKU Family'                = $sku.family;
                            'Tier'                      = $sku.tier;
                            'Capacity'                  = $sku.capacity;
                            'Postgre Version'           = $data.version;
                            'Private Endpoint'          = $PVTENDP;
                            'Backup Retention Days'     = $data.storageProfile.backupRetentionDays;
                            'Geo-Redundant Backup'      = $data.backup.geoRedundantBackup ;
                            'Auto Grow'                 = $data.storageProfile.storageAutogrow;
                            'Storage MB'                = $data.storageProfile.storageMB;
                            'Public Network Access'     = $data.publicNetworkAccess;
                            'Admin Login'               = $data.administratorLogin;
                            'Infrastructure Encryption' = $data.InfrastructureEncryption;
                            'Minimum TLS Version'       = "$($data.minimalTlsVersion -Replace '_', '.' -Replace 'tls', 'TLS')";
                            'State'                     = $data.userVisibleState;
                            'Replica Capacity'          = $data.replicaCapacity;
                            'Replication Role'          = $data.replicationRole;
                            'BYOK Enforcement'          = $data.byokEnforcement;
                            'SSL Enforcement'           = $data.sslEnforcement;
                            'Resource U'                = $ResUCount;
                            'Tag Name'                  = [string]$Tag.Name;
                            'Tag Value'                 = [string]$Tag.Value
                        }
                        $tmp += $obj
                        if ($ResUCount -eq 1) { $ResUCount = 0 } 
                    }                
            }
            $tmp
        }

}
<######## Resource Excel Reporting Begins Here ########>

Else {
    <######## $SmaResources.(RESOURCE FILE NAME) ##########>

    if ($SmaResources.POSTGREFlex) {

        $TableName = ('POSTGRETableFlex_'+($SmaResources.POSTGREFlex.id | Select-Object -Unique).count)
        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat 0

        $condtxt = @()
        $condtxt += New-ConditionalText FALSE -Range J:J
        $condtxt += New-ConditionalText FALSO -Range J:J
        $condtxt += New-ConditionalText Disabled -Range L:L
        $condtxt += New-ConditionalText Enabled -Range O:O
        $condtxt += New-ConditionalText TLSEnforcementDisabled -Range R:R
        $condtxt += New-ConditionalText Disabled -Range W:W


        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('Resource Group')
        $Exc.Add('Name')
        $Exc.Add('Zones')
        $Exc.Add('RTO')
        $Exc.Add('RPO')
        $Exc.Add("SLA")
        $Exc.Add('Location')
        $Exc.Add('SKU')
        $Exc.Add('SKU Family')
        $Exc.Add('Tier')
        $Exc.Add('Capacity')
        $Exc.Add('Postgre Version')
        $Exc.Add('Private Endpoint')
        $Exc.Add('Backup Retention Days')
        $Exc.Add('Geo-Redundant Backup')
        $Exc.Add('Auto Grow')
        $Exc.Add('Storage MB')
        $Exc.Add('Public Network Access')
        $Exc.Add('Admin Login')
        $Exc.Add('Infrastructure Encryption')
        $Exc.Add('Minimum TLS Version')
        $Exc.Add('State')
        $Exc.Add('Replica Capacity')
        $Exc.Add('Replication Role')
        $Exc.Add('BYOK Enforcement')
        $Exc.Add('SSL Enforcement')
        if($InTag)
            {
                $Exc.Add('Tag Name')
                $Exc.Add('Tag Value') 
            }

        $ExcelVar = $SmaResources.POSTGREFlex 

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'PostgreSQLFlex' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -TableStyle $tableStyle -ConditionalText $condtxt -Style $Style

         ## Export to Combine Tab

        ## Create New ExcCombine Object by copy from $Exc from selected column Subscription, Resource Group, VM Name, Zone 
        $ExcCombine = New-Object System.Collections.Generic.List[System.Object]
        $ExcCombine.Add('Subscription')
        $ExcCombine.Add('Resource Group')
        $ExcCombine.Add('Azure Services')
        $ExcCombine.Add('Resource Name')
        $ExcCombine.Add('Zones')
        $ExcCombine.Add('Location')

        # # Export-Excel with No Table in the worksheet ResourcesCombine
        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $ExcCombine | 
        Export-Excel -Path $File -WorksheetName 'Combine'  -MaxAutoSizeRows 100  -Style $Style, $StyleExt  -Append
    }
    <######## Insert Column comments and documentations here following this model #########>
}