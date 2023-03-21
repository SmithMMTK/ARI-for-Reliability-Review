# Import the Excel file as a PowerShell object
Import-Module ImportExcel



# Set the path to the Excel file you want to modify
#$File = "/Users/smithm/AzureResourceInventory/a smithmio AzureResourceInventory_Report_2023-03-21_17_03.xlsx"
$File = "/Users/smithm/AzureResourceInventory/a mimo AzureResourceInventory_Report_2023-03-21_17_07.xlsx"

$current_time = Get-Date
$current_time_string = $current_time.ToString("yyyy-MM-dd HH:mm:ss")


$NewFile = ($File + "_" + (get-date -Format "yyyy-MM-dd_HH_mm") + ".xlsx")
##$NewFile = $File + $current_time_string +  ".xlsx"

$TableStyle = "Light20"

#Import the "Combine" worksheet from the Excel file as a PowerShell object
$Excel = Import-Excel -Path $File -WorksheetName "Combine"


# Create new column "status" and put text "online" in all rows where Zones is not blank
#$Excel | Add-Member -MemberType NoteProperty -Name "status" -Value "online" -Force
#$Excel | Where-Object { $_.Zones -ne $null } | ForEach-Object { $_.status = "online" }

function evaluateZonal($s)
{
    # Count the number of matches of '1', '2', and '3'
    $count = 0

    if ($s -eq "Zone Redundant") 
    {
        return $true
    }
    else
    {
        if ($s -match "1"){$count = $count + 1 }
        if ($s -match "2"){$count=$count+1}
        if ($s -match "3"){$count=$count+1}

        if ($count -ge 2){ return $true } else { return $false }
    }
    
}




# Create new column "condition" and loop each component to put custom evaluation and write back to main object
$Excel | Add-Member -MemberType NoteProperty -Name "condition" -Value $null -Force

# Evalute each object in Zones, if empty set condition = Risky, if container at lease two zones set condition = Safe
$Excel | ForEach-Object {

    if (evaluateZonal $_.Zones ) {
        $_.condition = "Safe"

    }
    else {
        $_.condition = "Risk"
    }
}

#$Excel | ForEach-Object {
#    if ($_.Zones -eq $null) {
#        $_.condition = "Risk"
##    }
    # Elesif $_.Zones container at lease two zones is safe then put "Safe"
 #   elseif ()
#}


$Style = New-ExcelStyle -HorizontalAlignment Left -Width 20 -NumberFormat 0
$Excel | Export-Excel -Path $NewFile -WorksheetName "Combine" -Style $Style -TableStyle $TableStyle 
