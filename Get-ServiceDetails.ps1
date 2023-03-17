function Get-ServiceDetails {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Type,

        [Parameter(Mandatory=$true)]
        [string]$Zonal
    )

    # Import the CSV file
    $data = Import-Csv -Path 'zonal.csv'

    Write-Host $data
    # Select the rows where the "Type" column equals the specified type and the "Zonal" column equals the specified zonal
    $selectedRows = $data | Where-Object { $_.Type -eq $Type -and $_.Zonal -eq $Zonal }

    # Select the RTO, RPO, and SLA columns for the selected rows
    $selectedColumns = $selectedRows | Select-Object RTO, RPO, SLA

    # Convert the selected columns to a JSON object
    $jsonOutput = $selectedColumns | ConvertTo-Json

    # Return the JSON object
    return $jsonOutput
}