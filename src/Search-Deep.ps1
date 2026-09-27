<#
.SYNOPSIS
    PS-FastSearch Deep Search Engine

.DESCRIPTION
    Performs a direct filesystem search using .NET APIs.

    Searches:
        - Files
        - Folders
        - Files and Folders

    Features:
        - Iterative directory traversal
        - Queue-based scanning
        - Access denied handling
        - I/O error handling
        - Reparse-point detection
        - Search statistics
        - Case-insensitive name matching
        - Wildcard support
        - Safe continuation when individual directories/files fail

.AUTHOR
    Madhushanka Lakmal

.VERSION
    0.2.0
#>

function Search-Deep {

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
    # Validate Search Path
    # ============================================================

    try {

        $ResolvedPath = [System.IO.Path]::GetFullPath(
            (Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path
        )

    }
    catch {

        throw "Invalid search path: $Path"
    }

    if (-not [System.IO.Directory]::Exists($ResolvedPath)) {

        throw "Search path is not a directory: $ResolvedPath"
    }

    # ============================================================
    # Prepare Search Pattern
    # ============================================================

    $SearchPattern = $Name

    # If user does not provide wildcards,
    # automatically search for the name anywhere inside the filename.

    if ($SearchPattern -notmatch '[\*\?]') {

        $SearchPattern = "*$SearchPattern*"
    }

    # ============================================================
    # Statistics
    # ============================================================

    $Results = [System.Collections.Generic.List[object]]::new()

    $DirectoriesScanned = 0
    $FilesScanned       = 0
    $AccessDenied       = 0
    $IOErrorCount       = 0
    $ReparsePoints      = 0
    $OtherErrors        = 0

    # ============================================================
    # Timer
    # ============================================================

    $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    # ============================================================
    # Directory Queue
    # ============================================================

    # IMPORTANT:
    # Create an empty Queue first.
    # Then add the first directory using Enqueue().
    #
    # This avoids:
    # "Argument types do not match"

    $Queue = [System.Collections.Generic.Queue[string]]::new()

    $Queue.Enqueue($ResolvedPath)

    # ============================================================
    # Search Loop
    # ============================================================

    while ($Queue.Count -gt 0) {

        $CurrentDirectory = $Queue.Dequeue()

        $DirectoriesScanned++

        # ========================================================
        # Get Directory Information
        # ========================================================

        try {

            $DirectoryInfo = [System.IO.DirectoryInfo]::new(
                $CurrentDirectory
            )

        }
        catch {

            $OtherErrors++
            continue
        }

        # ========================================================
        # Check Current Directory Reparse Point
        # ========================================================

        try {

            if (($DirectoryInfo.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {

                $ReparsePoints++
                continue
            }

        }
        catch {

            $OtherErrors++
            continue
        }

        # ========================================================
        # Search Current Directory Name
        # ========================================================

        if ($Type -eq "Folder" -or $Type -eq "Both") {

            try {

                if ($DirectoryInfo.Name -like $SearchPattern) {

                    $Results.Add(
                        [PSCustomObject]@{
                            Path         = $DirectoryInfo.FullName
                            Name         = $DirectoryInfo.Name
                            Type         = "Folder"
                            Size         = $null
                            DateModified = $DirectoryInfo.LastWriteTime
                        }
                    )
                }

            }
            catch {

                $OtherErrors++
            }
        }

        # ========================================================
        # Enumerate Files
        # ========================================================

        try {

            foreach (
                $File in [System.IO.Directory]::EnumerateFiles(
                    $CurrentDirectory
                )
            ) {

                $FilesScanned++

                try {

                    $FileInfo = [System.IO.FileInfo]::new($File)

                    if ($FileInfo.Name -like $SearchPattern) {

                        if ($Type -eq "File" -or $Type -eq "Both") {

                            $Results.Add(
                                [PSCustomObject]@{
                                    Path         = $FileInfo.FullName
                                    Name         = $FileInfo.Name
                                    Type         = "File"
                                    Size         = $FileInfo.Length
                                    DateModified = $FileInfo.LastWriteTime
                                }
                            )
                        }
                    }

                }
                catch [System.UnauthorizedAccessException] {

                    $AccessDenied++
                    continue
                }
                catch [System.IO.IOException] {

                    $IOErrorCount++
                    continue
                }
                catch {

                    $OtherErrors++
                    continue
                }
            }

        }
        catch [System.UnauthorizedAccessException] {

            $AccessDenied++
        }
        catch [System.IO.IOException] {

            $IOErrorCount++
        }
        catch {

            $OtherErrors++
        }

        # ========================================================
        # Enumerate Subdirectories
        # ========================================================

        try {

            foreach (
                $Directory in [System.IO.Directory]::EnumerateDirectories(
                    $CurrentDirectory
                )
            ) {

                try {

                    $DirectoryInfo = [System.IO.DirectoryInfo]::new(
                        $Directory
                    )

                    # Skip symbolic links / junctions / reparse points

                    if (
                        ($DirectoryInfo.Attributes -band
                        [System.IO.FileAttributes]::ReparsePoint) -ne 0
                    ) {

                        $ReparsePoints++
                        continue
                    }

                    # Add directory to queue

                    $Queue.Enqueue(
                        $DirectoryInfo.FullName
                    )

                }
                catch [System.UnauthorizedAccessException] {

                    $AccessDenied++
                    continue
                }
                catch [System.IO.IOException] {

                    $IOErrorCount++
                    continue
                }
                catch {

                    $OtherErrors++
                    continue
                }
            }

        }
        catch [System.UnauthorizedAccessException] {

            $AccessDenied++
        }
        catch [System.IO.IOException] {

            $IOErrorCount++
        }
        catch {

            $OtherErrors++
        }
    }

    # ============================================================
    # Stop Timer
    # ============================================================

    $Stopwatch.Stop()

    # ============================================================
    # Statistics Object
    # ============================================================

    $Statistics = [PSCustomObject]@{

        ResultsFound       = $Results.Count

        DirectoriesScanned = $DirectoriesScanned

        FilesScanned       = $FilesScanned

        AccessDenied       = $AccessDenied

        IOErrorCount       = $IOErrorCount

        ReparsePoints      = $ReparsePoints

        OtherErrors        = $OtherErrors

        SearchTimeSeconds  = [Math]::Round(
            $Stopwatch.Elapsed.TotalSeconds,
            3
        )
    }

    # ============================================================
    # Return Search Result
    # ============================================================

    return [PSCustomObject]@{

        Results    = $Results

        Statistics = $Statistics
    }
}