<#
.SYNOPSIS
    PS-FastSearch Indexed Search Engine

.DESCRIPTION
    Searches the Windows Search Index using Search.CollatorDSO.

    Supports:
        - File
        - Folder
        - Both

.AUTHOR
    Madhushanka Lakmal

.VERSION
    0.2.1
#>

function Search-Indexed {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [ValidateSet("File", "Folder", "Both")]
        [string]$Type = "File"
    )

    # ============================================================
    # Validate Path
    # ============================================================

    try {

        $ResolvedPath = (
            Resolve-Path `
                -LiteralPath $Path `
                -ErrorAction Stop
        ).Path

    }
    catch {

        throw "Invalid search path: $Path"
    }

    # ============================================================
    # Prepare Search Term
    # ============================================================

    $SearchTerm = $Name

    # Remove PowerShell wildcard characters.
    # Windows Search CONTAINS handles the actual search.

    $SearchTerm = $SearchTerm.Replace("*", "")
    $SearchTerm = $SearchTerm.Replace("?", "")

    if ([string]::IsNullOrWhiteSpace($SearchTerm)) {

        throw "Search name cannot be empty."
    }

    # Escape SQL single quotes

    $SearchTerm = $SearchTerm.Replace("'", "''")

    # ============================================================
    # Build Search Scope
    # ============================================================

    $ScopePath = $ResolvedPath.TrimEnd('\')

    # C: becomes C:\
    if ($ScopePath.Length -eq 2 -and $ScopePath[1] -eq ':') {

        $ScopePath += '\'
    }

    $Scope = "file:$ScopePath"

    # ============================================================
    # Build Type Filter
    # ============================================================

    switch ($Type) {

        "File" {

            $TypeFilter = @"
AND System.Kind <> 'folder'
"@
        }

        "Folder" {

            $TypeFilter = @"
AND System.Kind = 'folder'
"@
        }

        "Both" {

            $TypeFilter = ""
        }
    }

    # ============================================================
    # SQL Query
    # ============================================================

    $Query = @"
SELECT
    System.ItemPathDisplay,
    System.ItemName,
    System.ItemTypeText,
    System.Size,
    System.DateModified,
    System.Kind
FROM
    SystemIndex
WHERE
    SCOPE = '$Scope'
    AND CONTAINS(System.FileName, '$SearchTerm')
    $TypeFilter
ORDER BY
    System.ItemName
"@

    # ============================================================
    # Objects
    # ============================================================

    $Connection = $null
    $Command    = $null
    $Reader     = $null

    $Results = [System.Collections.Generic.List[object]]::new()

    $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    try {

        # ========================================================
        # Create Windows Search Connection
        # ========================================================

        $Connection = New-Object System.Data.OleDb.OleDbConnection

        $Connection.ConnectionString =
            "Provider=Search.CollatorDSO;Extended Properties='Application=Windows';"

        $Connection.Open()

        # ========================================================
        # Execute Query
        # ========================================================

        $Command = $Connection.CreateCommand()

        $Command.CommandText = $Query

        $Reader = $Command.ExecuteReader()

        # ========================================================
        # Read Results
        # ========================================================

        while ($Reader.Read()) {

            $ItemPath = $Reader["System.ItemPathDisplay"]
            $ItemName = $Reader["System.ItemName"]
            $ItemType = $Reader["System.ItemTypeText"]
            $ItemSize = $Reader["System.Size"]
            $Modified = $Reader["System.DateModified"]
            $ItemKind = $Reader["System.Kind"]

            # Determine result type

            if ($ItemKind -eq "folder") {

                $ResultType = "Folder"
            }
            else {

                $ResultType = "File"
            }

            # Handle DBNull

            if ($ItemSize -is [System.DBNull]) {

                $ItemSize = $null
            }

            if ($Modified -is [System.DBNull]) {

                $Modified = $null
            }

            # Add result

            $Results.Add(
                [PSCustomObject]@{
                    Path         = $ItemPath
                    Name         = $ItemName
                    Type         = $ResultType
                    Size         = $ItemSize
                    DateModified = $Modified
                    IndexedType  = $ItemType
                }
            )
        }

    }
    catch {

        throw "Indexed search failed: $($_.Exception.Message)"
    }
    finally {

        # ========================================================
        # Cleanup Reader
        # ========================================================

        if ($Reader) {

            try {
                $Reader.Close()
            }
            catch {}
        }

        # ========================================================
        # Cleanup Command
        # ========================================================

        if ($Command) {

            try {
                $Command.Dispose()
            }
            catch {}
        }

        # ========================================================
        # Cleanup Connection
        # ========================================================

        if ($Connection) {

            try {

                if (
                    $Connection.State -eq
                    [System.Data.ConnectionState]::Open
                ) {

                    $Connection.Close()
                }

                $Connection.Dispose()
            }
            catch {}
        }

        $Stopwatch.Stop()
    }

    # ============================================================
    # Statistics
    # ============================================================

    $Statistics = [PSCustomObject]@{

        ResultsFound      = $Results.Count

        SearchTimeSeconds = [Math]::Round(
            $Stopwatch.Elapsed.TotalSeconds,
            3
        )

        SearchType        = $Type

        SearchPath        = $ResolvedPath
    }

    # ============================================================
    # Return Object
    # ============================================================

    return [PSCustomObject]@{

        Results    = $Results

        Statistics = $Statistics
    }
}