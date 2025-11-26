Function Get-TableEntities {
    [CmdletBinding(SupportsShouldProcess)]
    Param
    (
        [Parameter(Mandatory)]
        [string]$TableName,

        [Parameter(Mandatory)]
        [string]$StorageAccount,

        [Parameter(Mandatory)]
        [string]$AccessKey,

        [Parameter()]
        [string]$Filter = $null
    )

    begin {

        if ($AccessKey.StartsWith('?')) {
             $AccessKey = $AccessKey.TrimStart('?')
        }

        $TableURL = "https://$($StorageAccount).table.core.windows.net/$($TableName)?$($AccessKey)"

        $Headers = @{
            "x-ms-version" = '2020-04-08'
            Accept         = 'application/json;odata=nometadata'
        }
    }

    process {
        $GetRequest = @{
            Method      = 'GET'
            Uri         = $TableURL
            Headers     = $Headers
            ContentType = 'application/json'
            Body        = $Null
        }

        if (-not [string]::IsNullOrEmpty($Filter)) {
           $GetRequest.Body = @{
                '$Filter' = $Filter
           }
        }
        
        return (Invoke-RestMethod @GetRequest).value
    }
}

$Config = $configuration | ConvertFrom-Json

$TableRequests = @{
    StorageAccount = $Config.StorageAccount
    AccessKey      = $Config.AccessKey
    Confirm        = $false
    WhatIf         = [System.Convert]::ToBoolean($dryrun)
}

 
try {
    # Retrieve data
    Write-Information "Retrieving data from HR system API"

    $TableRequests.TableName = $Config.Table.Employees
    $Employees = Get-TableEntities @TableRequests

    $TableRequests.TableName = $Config.Table.Contracts
    $Contracts = Get-TableEntities @TableRequests

    $Departments = @{}
    $Locations = @{}
    $Titles = @{}

    Get-TableEntities @TableRequests -TableName $Config.Table.Departments | Foreach-Object {
        $Departments.Add($_.ExternalId, $_)
    }
    Get-TableEntities @TableRequests -TableName $Config.Table.Locations | Foreach-Object {
        $Locations.Add($_.ExternalId, $_)
    }
    Get-TableEntities @TableRequests -TableName $Config.Table.Titles | Foreach-Object {
        $Titles.Add($_.ExternalId, $_)
    }
    
    Write-Information "Successfully retrieved data from HR system"

    # Enrich contracts
    Write-Information "Enriching contracts with department, title and location information"

    $Contracts | ForEach-Object {
        if ($Departments.ContainsKey($_.DepartmentExternalId)) {
            $_ | Add-Member -MemberType NoteProperty -Name 'Department' -Value $Departments[$_.DepartmentExternalId]
            $_.PSObject.Properties.Remove('DepartmentExternalId')
        }
        if ($Locations.ContainsKey($_.LocationExternalId)) {
            $_ | Add-Member -MemberType NoteProperty -Name 'Location' -Value $Locations[$_.LocationExternalId]
            $_.PSObject.Properties.Remove('LocationExternalId')
        }
        if ($Titles.ContainsKey($_.TitleExternalId)) {
            $_ | Add-Member -MemberType NoteProperty -Name 'Title' -Value $Titles[$_.TitleExternalId]
            $_.PSObject.Properties.Remove('TitleExternalId')
        }
    }

    $Contracts = $Contracts | Group-Object PersonExternalId -AsString -AsHashTable

    Write-Information "Successfully enriched contracts"

    # Enrich and output persons
    Write-Information "Enriching persons and output them to HelloID"

    $Employees | ForEach-Object {
        $Employee = $PSItem

        if ($Contracts[$Employee.ExternalId]) {
            $Employee | Add-Member -MemberType NoteProperty -Name 'Contracts' -Value $Contracts[$Employee.ExternalId]
        }

        $DisplayName = switch ($Employee.Convention) {
            1 {"$($Employee.Nickname) $($Employee.FamilyNamePrefix) $($Employee.FamilyName) - $($Employee.FamilyNamePartnerPrefix) $($Employee.FamilyNamePartner)"}
            2 {"$($Employee.Nickname) $($Employee.FamilyNamePartnerPrefix) $($Employee.FamilyNamePartner)"}
            3 {"$($Employee.Nickname) $($Employee.FamilyNamePartnerPrefix) $($Employee.FamilyNamePartner) - $($Employee.FamilyNamePrefix) $($Employee.FamilyName)"}
            default {"$($Employee.Nickname) $($Employee.FamilyNamePrefix) $($Employee.FamilyName)"}
        }

        $DisplayName = ($DisplayName -replace '\s+', ' ') + " ($($Employee.ExternalId))"

        $Employee | Add-Member -MemberType NoteProperty -Name 'DisplayName' -Value $DisplayName

        Write-Output $Employee | ConvertTo-Json -Depth 10
    }

    Write-Information "Import successful"
} catch {
    Write-Verbose "Import failed. Error: $_"
    Throw "Import failed. Error: $_"
}