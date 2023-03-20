<#
.Synopsis
Inventory for Azure SQLDB

.DESCRIPTION
This script consolidates information for all microsoft.sql/servers/databases resource provider in $Resources variable. 
Excel Sheet Name: SQLDB

.Link
https://github.com/microsoft/ARI/Modules/Data/SQLDB.ps1

.COMPONENT
This powershell Module is part of Azure Resource Inventory (ARI)

.NOTES
Version: 2.2.0
First Release Date: 19th November, 2020
Authors: Claudio Merola and Renato Gregio 

#>

<######## Default Parameters. Don't modify this ########>

param($SCPath, $Sub, $Intag, $Resources, $Task , $File, $SmaResources, $TableStyle) 



if ($Task -eq 'Processing') {

       $SQLDB = $Resources | Where-Object { $_.TYPE -eq 'microsoft.sql/servers/databases' -and $_.name -ne 'master' }



    if($SQLDB)
        {
   
            $tmp = @()

            foreach ($1 in $SQLDB) {
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.id -eq $1.subscriptionId }
                $data = $1.PROPERTIES
                $DBServer = [string]$1.id.split("/")[8]
                $Tags = if(![string]::IsNullOrEmpty($1.tags.psobject.properties)){$1.tags.psobject.properties}else{'0'}

                # Load Get-Service Detail Module
                . ./Get-ServiceDetails.ps1                 


                # If $data.zoneRedundant is not null then it is a zone redundant database so generate output string "1, 2, 3"
                if ($data.zoneRedundant) 
                {
                    $zonal = "1, 2, 3"
                    $jsonOutput = Get-ServiceDetails -Type 'AzureSQL'  -Resilience 'Zonal'
                } 
                else 
                { 
                    $zonal = ""
                    if ($data.storageAccountType -eq 'LRS') 
                    {
                        $jsonOutput = Get-ServiceDetails -Type 'AzureSQL-LRS'  -Resilience 'Single'
                    } 
                        elseif ($data.storageAccountType -eq 'GRS')
                        {
                            $jsonOutput = Get-ServiceDetails -Type 'AzureSQL-GRS'  -Resilience 'Single'
                        }
                        else
                            {
                                $jsonOutput = Get-ServiceDetails -Type 'AzureSQL-Other'  -Resilience 'Single'
                            }
                }

                # Get RTO information from $jsonOutput field RTO
                $RTO = $jsonOutput | ConvertFrom-Json | Select-Object -ExpandProperty RTO

                # Get RPO information from $jsonOutput field RPO
                $RPO = $jsonOutput | ConvertFrom-Json | Select-Object -ExpandProperty RPO
                
                # Get SLA information from $jsonOutput field SLA
                $SLA = $jsonOutput | ConvertFrom-Json | Select-Object -ExpandProperty SLA

                # Set Type value for combine tab
                $azureServices = 'Azure SQL Database'

                    foreach ($Tag in $Tags) {
                        $obj = @{
                            'ID'                         = $1.id;
                            'Subscription'               = $sub1.Name;
                            'Resource Group'             = $1.RESOURCEGROUP;
                            'Name'                       = $1.NAME;
                            'Resource Name'              = $1.NAME;
                            'Azure Services'             = $azureServices;
                            'Location'                   = $1.LOCATION;
                            'RTO'                           = [string]$RTO;
                            'RPO'                           = [string]$RPO;
                            'SLA'                           = [string]$SLA;                            
                            'Storage Account Type'       = $data.storageAccountType;
                            'Database Server'            = $DBServer;
                            'Default Secondary Location' = $data.defaultSecondaryLocation;
                            'Status'                     = $data.status;
                            'DTU Capacity'               = $data.currentSku.capacity;
                            'DTU Tier'                   = $data.requestedServiceObjectiveName;
                            #'Zone Redundant'             = $data.zoneRedundant;
                            'Zones'             = $zonal;
                            'Catalog Collation'          = $data.catalogCollation;
                            'Read Replica Count'         = $data.readReplicaCount;
                            'Data Max Size (GB)'         = (($data.maxSizeBytes / 1024) / 1024) / 1024;
                            'Resource U'                 = $ResUCount;
                            'Tag Name'                   = [string]$Tag.Name;
                            'Tag Value'                  = [string]$Tag.Value
                        }
                        $tmp += $obj
                        if ($ResUCount -eq 1) { $ResUCount = 0 } 
                    }               
            }
            $tmp
        }
}
else {
    if ($SmaResources.SQLDB) {

        $TableName = ('SQLDBTable_'+($SmaResources.SQLDB.id | Select-Object -Unique).count)
        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat 0
        
        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('Resource Group')
        $Exc.Add('Name')
        $Exc.Add('Zones')
        $Exc.Add('RTO')
        $Exc.Add('RPO')
        $Exc.Add("SLA")
        $Exc.Add('Location')
        $Exc.Add('Storage Account Type')
        $Exc.Add('Database Server')
        $Exc.Add('Default Secondary Location')
        $Exc.Add('Status')
        $Exc.Add('DTU Capacity')
        $Exc.Add('DTU Tier')
        $Exc.Add('Data Max Size (GB)')
        
        $Exc.Add('Catalog Collation')
        $Exc.Add('Read Replica Count')
        if($InTag)
            {
                $Exc.Add('Tag Name')
                $Exc.Add('Tag Value') 
            }

        $ExcelVar = $SmaResources.SQLDB 

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'SQL DBs' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -TableStyle $tableStyle -Style $Style

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
}