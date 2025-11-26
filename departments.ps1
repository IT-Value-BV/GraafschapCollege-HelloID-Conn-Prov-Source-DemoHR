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
    TableName      = $Config.Table.Departments
    StorageAccount = $Config.StorageAccount
    AccessKey      = $Config.AccessKey
    Confirm        = $false
    WhatIf         = [System.Convert]::ToBoolean($dryrun)
}

# Retrieve data 
try {
    Write-Information "Retrieving departments from HR system API"

    $Departments = Get-TableEntities @TableRequests

    $Departments | ForEach-Object {
        Write-Output $_ | ConvertTo-Json
    }

    Write-Information "Successfully retrieved departments"
} catch {
    Write-Verbose "Failed to retrieve departments form HR system API. Error: $_"
    Throw "Failed to retrieve departments form HR system API. Error: $_"
}