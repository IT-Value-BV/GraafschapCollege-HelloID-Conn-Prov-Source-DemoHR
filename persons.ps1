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
    TableName      = $null
    StorageAccount = $C.StorageAccount
    AccessKey      = $C.AccessKey
    Confirm        = $false
    WhatIf         = [System.Convert]::ToBoolean($dryrun)
}

# Retrieve data 
try {
    Write-Information "Retrieving data from HR system API"

    $TableRequests.TableName = $c.Table.Employees
    $Employees = Get-TableEntities @TableRequests

    $TableRequests.TableName = $c.Table.Contracts
    $Contracts = Get-TableEntities @TableRequests

    $TableRequests.TableName = $c.Table.Departments
    $Departments = Get-TableEntities @TableRequests
    $Departments = $Departments | Group-Object ExternalId -AsString -AsHashTable

    $TableRequests.TableName = $c.Table.Titles
    $Titles = Get-TableEntities @TableRequests
    $Titles = $Titles | Group-Object ExternalId -AsString -AsHashTable

    $TableRequests.TableName = $c.Table.Locations
    $Locations = Get-TableEntities @TableRequests
    $Locations = $Locations | Group-Object ExternalId -AsString -AsHashTable

    Write-Information "Successfully retrieved data from HR system"
} catch {
    Write-Verbose "Failed to retrieve data from HR system. Error: $_"
    Throw "Failed to retrieve data from HR system. Error: $_"
}

# Enrich contracts
try {
    Write-Information "Enriching contracts with department, title and location information"

    $Contracts | ForEach-Object {
        if ($Departments[$_.DepartmentExternalId]) {
            $_ | Add-Member -MemberType NoteProperty -Name 'DepartmentName' -Value $Departments[$_.DepartmentExternalId].DisplayName
        }

        if ($Titles[$_.TitleExternalId]) {
            $_ | Add-Member -MemberType NoteProperty -Name 'TitleName' -Value $Titles[$_.TitleExternalId].DisplayName
        }

        if ($Locations[$_.LocationExternalId]) {
            $_ | Add-Member -MemberType NoteProperty -Name 'LocationName' -Value $Locations[$_.LocationExternalId].DisplayName
            $_ | Add-Member -MemberType NoteProperty -Name 'LocationCity' -Value $Locations[$_.LocationExternalId].City
            $_ | Add-Member -MemberType NoteProperty -Name 'LocationHouseNumber' -Value $Locations[$_.LocationExternalId].HouseNumber
            $_ | Add-Member -MemberType NoteProperty -Name 'LocationPostalCode' -Value $Locations[$_.LocationExternalId].PostalCode
            $_ | Add-Member -MemberType NoteProperty -Name 'LocationStreet' -Value $Locations[$_.LocationExternalId].Street
            $_ | Add-Member -MemberType NoteProperty -Name 'LocationType' -Value $Locations[$_.LocationExternalId].Type
        }
    }

    $Contracts = $Contracts | Group-Object PersonExternalId -AsString -AsHashTable

    Write-Information "Successfully enriched contracts"
} catch {
    Write-Verbose "Failed to enrich contracts. Error: $_"
    Throw "Failed to enrich contracts. Error: $_"
}

# Enrich and output persons
try {
    Write-Information "Enriching persons and output them to HelloID"

    $Employees | ForEach-Object {
        if ($Contracts[$_.ExternalId]) {
            $_ | Add-Member -MemberType NoteProperty -Name 'Contracts' -Value $Contracts[$_.ExternalId]
        }

        if ($_.FamilyNamePrefix) {
            $DisplayName = "$($_.Nickname) $($_.FamilyNamePrefix) $($_.FamilyName) ($($_.ExternalId))"
        } else {
            $DisplayName = "$($_.Nickname) $($_.FamilyName) ($($_.ExternalId))"
        }

        $_ | Add-Member -MemberType NoteProperty -Name 'DisplayName' -Value $DisplayName

        Write-Output $_ | ConvertTo-Json
    }

    Write-Information "Import successful"
} catch {
    Write-Verbose "Failed to enrich persons and output to HelloID. Error: $_"
    Throw "Failed to enrich persons and output to HelloID. Error: $_"
}