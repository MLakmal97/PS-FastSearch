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

    $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    $Results = [System.Collections.Generic.List[object]]::new()

    try {

        # ------------------------------------------------------------
        # Resolve and validate path
        # ------------------------------------------------------------

        $ResolvedPath = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path

        if (-not (Test-Path -LiteralPath $ResolvedPath -PathType Container)) {
            throw "Search path is not a directory: $ResolvedPath"
        }

        # ------------------------------------------------------------
        # Clean search term
        # ------------------------------------------------------------

        $SearchTerm = $Name.Trim()

        # Remove user wildcards because Windows Search queries
        # are constructed separately below.
        $SearchTerm = $SearchTerm -replace '[*?]', ''

        if ([string]::IsNullOrWhiteSpace($SearchTerm)) {
            throw "Search name cannot be empty."
        }

        # Escape single quotes for the Windows Search query.
        $SearchTerm = $SearchTerm.Replace("'", "''")

        # ------------------------------------------------------------
        # Build Windows Search scope
        # ------------------------------------------------------------

        $ScopePath = $ResolvedPath.TrimEnd('\')

        if ($ScopePath -match '^[A-Za-z]:$') {
            $ScopePath += '\'
        }

        $Scope = "file:$ScopePath"

        # ------------------------------------------------------------
        # Open Windows Search connection
        # ------------------------------------------------------------

        $Connection = New-Object System.Data.OleDb.OleDbConnection

        $Connection.ConnectionString =
            "Provider=Search.CollatorDSO;Extended Properties='Application=Windows';"

        $Connection.Open()

        # ------------------------------------------------------------
        # Helper function
        # ------------------------------------------------------------

        function Invoke-IndexedQuery {
            param(
                [Parameter(Mandatory = $true)]
                [string]$Query
            )

            $Command = $null
            $Reader = $null

            try {

                $Command = $Connection.CreateCommand()
                $Command.CommandText = $Query

                $Reader = $Command.ExecuteReader()

                while ($Reader.Read()) {

                    $ItemPath = [string]$Reader["System.ItemPathDisplay"]
                    $ItemName = [string]$Reader["System.ItemName"]
                    $ItemType = [string]$Reader["System.ItemTypeText"]
                    $Kind     = [string]$Reader["System.Kind"]

                    $Size = $null
                    $DateModified = $null

                    if ($Reader["System.Size"] -ne [DBNull]::Value) {
                        $Size = [Int64]$Reader["System.Size"]
                    }

                    if ($Reader["System.DateModified"] -ne [DBNull]::Value) {
                        $DateModified = [datetime]$Reader["System.DateModified"]
                    }

                    $Results.Add(
                        [PSCustomObject]@{
                            Path         = $ItemPath
                            Name         = $ItemName
                            Type         = $ItemType
                            Size         = $Size
                            DateModified = $DateModified
                            IndexedType  = $Kind
                        }
                    )
                }

            }
            finally {

                if ($Reader) {
                    $Reader.Close()
                    $Reader.Dispose()
                }

                if ($Command) {
                    $Command.Dispose()
                }
            }
        }

        # ------------------------------------------------------------
        # File search
        # ------------------------------------------------------------

        if ($Type -eq "File" -or $Type -eq "Both") {

            $FileQuery = @"
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
    AND System.Kind <> 'folder'
    AND CONTAINS(System.FileName, '$SearchTerm')
ORDER BY
    System.ItemName
"@

            Invoke-IndexedQuery -Query $FileQuery
        }

        # ------------------------------------------------------------
        # Folder search
        #
        # Windows Search indexing contains folder records, but
        # CONTAINS(System.ItemName, ...) does not reliably match
        # folder names with this provider.
        #
        # LIKE works for folder-name matching.
        # ------------------------------------------------------------

        if ($Type -eq "Folder" -or $Type -eq "Both") {

            $FolderQuery = @"
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
    AND System.Kind = 'folder'
    AND System.ItemName LIKE '%$SearchTerm%'
ORDER BY
    System.ItemName
"@

            Invoke-IndexedQuery -Query $FolderQuery
        }

        # ------------------------------------------------------------
        # Remove duplicate paths
        # ------------------------------------------------------------

        $UniqueResults = @(
            $Results |
                Group-Object -Property Path |
                ForEach-Object {
                    $_.Group[0]
                }
        )

        $Stopwatch.Stop()

        # ------------------------------------------------------------
        # Return structured result
        # ------------------------------------------------------------

        [PSCustomObject]@{

            Results = $UniqueResults

            Statistics = [PSCustomObject]@{
                ResultsFound       = $UniqueResults.Count
                SearchTimeSeconds  = [math]::Round(
                    $Stopwatch.Elapsed.TotalSeconds,
                    3
                )
                SearchType         = $Type
                SearchPath         = $ResolvedPath
                SearchEngine       = "Windows Search Index"
                SearchScope        = "Indexed items only"
                Completeness       = "Indexed"
            }
        }

    }
    catch {

        $Stopwatch.Stop()

        throw "Indexed search failed: $($_.Exception.Message)"
    }
    finally {

        if ($Connection) {
            if ($Connection.State -eq [System.Data.ConnectionState]::Open) {
                $Connection.Close()
            }

            $Connection.Dispose()
        }
    }
}