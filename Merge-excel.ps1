## This script is for shortest time to test combine module

# Import the Excel file as a PowerShell object
Import-Module ImportExcel

# Set the path to the Excel file you want to modify
#$File = "/Users/smithm/AzureResourceInventory/a smithmio AzureResourceInventory_Report_2023-03-21_17_03.xlsx"
$File = "/Users/smithm/AzureResourceInventory/AzureResourceInventory_Report_2023-03-22_19_06.xlsx"
$FileTemplate = "./templates.xlsx"
$File_Resilience = ($File + " report " +  (get-date -Format "yyyy-MM-dd_HH_mm") + ".xlsx")


$TableStyle = "Light20"

#Import the "Combine" worksheet from the Excel file as a PowerShell object
$Excel = Import-Excel -Path $File -WorksheetName "Combine"
$Style = New-ExcelStyle -HorizontalAlignment Left -Width 20 -NumberFormat 0

Copy-Item $FileTemplate $File_Resilience

$Excel | Export-Excel -Path $File_Resilience -WorksheetName "Inventory" -Style $Style -TableStyle $TableStyle 
