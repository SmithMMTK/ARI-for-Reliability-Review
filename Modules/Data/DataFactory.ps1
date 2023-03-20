<#
.Synopsis
Inventory for Azure Container instance

.DESCRIPTION
This script consolidates information for all microsoft.datafactory/factories resource provider in $Resources variable. 
Excel Sheet Name: COMBINE

.Link


.COMPONENT
This powershell Module is part of Azure Resource Inventory (ARI)

.NOTES
Version: 2.2.0
First Release Date: 19th November, 2020
Authors: Claudio Merola and Renato Gregio 

#>

<######## Default Parameters. Don't modify this ########>

param($SCPath, $Sub, $Intag, $Resources, $Task ,$File, $SmaResources, $TableStyle)

If ($Task -eq 'Processing')
{

    <######### Insert the resource extraction here ########>

        $ADF = $Resources | Where-Object {($_.TYPE -eq 'microsoft.datafactory/factories') -or ($_.TYPE -eq 'microsoft.datafactory/datafactories')}


    <######### Insert the resource Process here ########>

    if($ADF)
        {
            $tmp = @()

            foreach ($1 in $ADF) {
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.id -eq $1.subscriptionId }
                #$data = $1.PROPERTIES
                $Tags = if(![string]::IsNullOrEmpty($1.tags.psobject.properties)){$1.tags.psobject.properties}else{'0'}
                
                # Set Type value for combine tab
                $azureServices = 'Azure Data Factory'
                        foreach ($Tag in $Tags) {
                            $obj = @{
                                'ID'                  = $1.id;
                                'Subscription'        = $sub1.Name;
                                'Resource Group'      = $1.RESOURCEGROUP;
                                'Zones'               = $1.zones;
                                'Resource Name'        = $1.NAME;
                                'Azure Services'       = $azureServices;
                                'Location'            = $1.LOCATION;
                            }
                            $tmp += $obj
                            if ($ResUCount -eq 1) { $ResUCount = 0 } 
                        }                                            
            }
            $tmp
        }
}

<######## Resource Excel Reporting Begins Here ########>

Else
{
    if ($SmaResources.DataFactory) {

        $TableName = ('DataFactoryTable_'+($SmaResources.DataFactory.id | Select-Object -Unique).count)
        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat 0
        


        $ExcelVar = $SmaResources.DataFactory 

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'Data Factory' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -TableStyle $tableStyle -Style $Style

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