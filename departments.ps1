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
    TableName      = $c.Table.Departments
    StorageAccount = $C.StorageAccount
    AccessKey      = $C.AccessKey
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