<#
.SYNOPSIS
    Windows Search indexed search provider for PS-FastSearch.

.DESCRIPTION
    Uses the Windows Search index through the
    Search.CollatorDSO OLE DB provider.

.VERSION
    0.2.0

.AUTHOR
    Madhushanka Lakmal
#>

#Requires -Version 5.1

function Search-Indexed {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Name

    )

    # ========================================================
    # Validate Path
    # ========================================================

    try {

        $ResolvedPath = (Resolve-Path -Path $Path -ErrorAction Stop).Path

    }
    catch {

        Write-Error "Search path does not exist: $Path"
        return

    }

    # ========================================================
    # Prepare Search Term
    # ========================================================

    # Remove wildcard characters because CONTAINS()
    # does not use PowerShell wildcard syntax.

    $SearchTerm = $Name.Replace("*", "").Replace("?", "").Trim()

    if ([string]::IsNullOrWhiteSpace($SearchTerm)) {

        Write-Error "Search name cannot be empty."
        return

    }

    # Escape single quotes for SQL

    $SearchTerm = $SearchTerm.Replace("'", "''")

    # ========================================================
    # Prepare Search Scope
    # ========================================================

    $ScopePath = $ResolvedPath.Replace("'", "''")

    $Scope = "file:$ScopePath"

    # ========================================================
    # Open Windows Search Connection
    # ========================================================

    $Connection = New-Object System.Data.OleDb.OleDbConnection

    try {

        $Connection.ConnectionString =
            "Provider=Search.CollatorDSO;Extended Properties='Application=Windows';"

        $Connection.Open()

    }
    catch {

        Write-Error "Unable to connect to Windows Search index."
        Write-Error $_.Exception.Message

        return

    }

    # ========================================================
    # Windows Search Query
    # ========================================================

    $Query = @"
SELECT
    System.ItemPathDisplay,
    System.ItemName,
    System.ItemTypeText,
    System.Size,
    System.DateModified
FROM
    SystemIndex
WHERE
    SCOPE = '$Scope'
    AND CONTAINS(System.FileName, '$SearchTerm')
"@

    # ========================================================
    # Execute Query
    # ========================================================

    $Command = $Connection.CreateCommand()

    $Command.CommandText = $Query

    $Reader = $null

    try {

        $Reader = $Command.ExecuteReader()

        while ($Reader.Read()) {

            [PSCustomObject]@{

                Path = $Reader["System.ItemPathDisplay"]

                Name = $Reader["System.ItemName"]

                Type = $Reader["System.ItemTypeText"]

                Size = $Reader["System.Size"]

                DateModified = $Reader["System.DateModified"]

            }

        }

    }
    catch {

        Write-Error "Windows Search query failed."
        Write-Error $_.Exception.Message

    }
    finally {

        if ($null -ne $Reader) {

            $Reader.Close()
            $Reader.Dispose()

        }

        $Connection.Close()
        $Connection.Dispose()

    }

}