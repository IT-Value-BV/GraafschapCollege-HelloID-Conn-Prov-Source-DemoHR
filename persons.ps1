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
        $FunctionAuditLogs = [Collections.Generic.List[PSCustomObject]]::new()

        $hmacsha     = [System.Security.Cryptography.HMACSHA256]::new()
        $hmacsha.key = [Convert]::FromBase64String($AccessKey)

        $TableURL = "https://$($StorageAccount).table.core.windows.net/$($TableName)"
        $GMTTime  = (Get-Date).ToUniversalTime().toString('R')

        $StringToSign = "$($GMTTime)`n/$($StorageAccount)/$($TableName)"
        $ComputeHash  = $hmacsha.ComputeHash([Text.Encoding]::UTF8.GetBytes($stringToSign))
        $Signature = [Convert]::ToBase64String($ComputeHash)

        $Headers = @{
            'x-ms-date'    = $GMTTime
            Authorization  = "SharedKeyLite $($storageAccount):$($signature)"
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

$c = $configuration | ConvertFrom-Json

$TableRequests = @{
    StorageAccount = $C.StorageAccount
    AccessKey      = $C.AccessKey
    Confirm        = $false
    WhatIf         = [System.Convert]::ToBoolean($dryrun)
}

 
try {
    # Retrieve data
    Write-Information "Retrieving data from HR system API"

    $TableRequests.TableName = $c.Table.Employees
    $Employees = Get-TableEntities @TableRequests

    $TableRequests.TableName = $c.Table.Contracts
    $Contracts = Get-TableEntities @TableRequests

    $Departments = @{}
    $Locations = @{}
    $Titles = @{}

    Get-TableEntities @TableRequests -TableName $c.Table.Departments | Foreach-Object {
        $Departments.Add($_.ExternalId, $_)
    }
    Get-TableEntities @TableRequests -TableName $c.Table.Locations | Foreach-Object {
        $Locations.Add($_.ExternalId, $_)
    }
    Get-TableEntities @TableRequests -TableName $c.Table.Titles | Foreach-Object {
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