<#
.SYNOPSIS
    PS-FastSearch - Fast interactive file and folder search utility.

.DESCRIPTION
    Searches files and folders recursively using .NET filesystem APIs.

    Version 0.1.2 introduces:
    - Iterative directory traversal
    - Safe filesystem exception handling
    - Error classification
    - Reparse point protection
    - Directory statistics
    - File statistics
    - Search timing

.VERSION
    0.1.2

.AUTHOR
    Madhushanka Lakmal
#>

#Requires -Version 5.1

Clear-Host

# ============================================================
# Configuration
# ============================================================

$Version = "0.1.2"
$Author  = "Madhushanka Lakmal"

# ============================================================
# Header
# ============================================================

Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "                 PS-FASTSEARCH" -ForegroundColor Cyan
Write-Host "            Fast File Search Utility" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Version : $Version"
Write-Host "Author  : $Author"
Write-Host ""

# ============================================================
# Search Type
# ============================================================

Write-Host "What do you want to search?"
Write-Host ""
Write-Host " [1] File"
Write-Host " [2] Folder"
Write-Host " [3] File and Folder"
Write-Host ""

do {

    $SearchType = Read-Host "Select option"

    if ($SearchType -notin @("1", "2", "3")) {

        Write-Host ""
        Write-Host "Invalid option. Please select 1, 2, or 3." -ForegroundColor Red
        Write-Host ""

    }

} while ($SearchType -notin @("1", "2", "3"))

# ============================================================
# Search Path
# ============================================================

Write-Host ""

$SearchPath = Read-Host "Search location [C:\]"

if ([string]::IsNullOrWhiteSpace($SearchPath)) {

    $SearchPath = "C:\"

}

# ============================================================
# Validate Path
# ============================================================

try {

    $ResolvedPath = (Resolve-Path -Path $SearchPath -ErrorAction Stop).Path

}
catch {

    Write-Host ""
    Write-Host "ERROR: Search path does not exist or cannot be accessed." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1

}

# ============================================================
# Search Name
# ============================================================

Write-Host ""

$SearchName = Read-Host "Search file/folder name"

if ([string]::IsNullOrWhiteSpace($SearchName)) {

    Write-Host ""
    Write-Host "ERROR: Search name cannot be empty." -ForegroundColor Red
    exit 1

}

# ============================================================
# Build Search Pattern
# ============================================================

if ($SearchName -notmatch '[\*\?]') {

    $SearchPattern = "*$SearchName*"

}
else {

    $SearchPattern = $SearchName

}

# ============================================================
# Search Configuration
# ============================================================

Write-Host ""
Write-Host "==============================================" -ForegroundColor DarkGray
Write-Host "Search Configuration" -ForegroundColor Yellow
Write-Host "==============================================" -ForegroundColor DarkGray

Write-Host "Location : $ResolvedPath"
Write-Host "Pattern  : $SearchPattern"

switch ($SearchType) {

    "1" {
        Write-Host "Type     : Files only"
    }

    "2" {
        Write-Host "Type     : Folders only"
    }

    "3" {
        Write-Host "Type     : Files and folders"
    }

}

Write-Host "==============================================" -ForegroundColor DarkGray
Write-Host ""

# ============================================================
# Statistics
# ============================================================

$Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

$FoundCount = 0

$DirectoriesScanned = 0
$FilesScanned       = 0

$AccessDeniedCount  = 0
$IOErrorCount       = 0
$ReparseCount       = 0
$OtherErrorCount    = 0

# ============================================================
# Directory Queue
# ============================================================

$DirectoryQueue = New-Object System.Collections.Generic.Queue[string]

$DirectoryQueue.Enqueue($ResolvedPath)

# ============================================================
# Search
# ============================================================

Write-Host "Searching..." -ForegroundColor Cyan
Write-Host ""

while ($DirectoryQueue.Count -gt 0) {

    # --------------------------------------------------------
    # Get next directory
    # --------------------------------------------------------

    $CurrentDirectory = $DirectoryQueue.Dequeue()

    $DirectoriesScanned++

    # --------------------------------------------------------
    # Enumerate Files
    # --------------------------------------------------------

    if ($SearchType -eq "1" -or $SearchType -eq "3") {

        try {

            $Files = [System.IO.Directory]::EnumerateFiles(
                $CurrentDirectory
            )

            foreach ($File in $Files) {

                $FilesScanned++

                try {

                    $FileName = [System.IO.Path]::GetFileName($File)

                    if ($FileName -like $SearchPattern) {

                        $FoundCount++

                        Write-Host $File

                    }

                }
                catch {

                    $OtherErrorCount++

                }

            }

        }
        catch [System.UnauthorizedAccessException] {

            $AccessDeniedCount++

        }
        catch [System.IO.IOException] {

            $IOErrorCount++

        }
        catch {

            $OtherErrorCount++

        }

    }

    # --------------------------------------------------------
    # Enumerate Directories
    # --------------------------------------------------------

    try {

        $Directories = [System.IO.Directory]::EnumerateDirectories(
            $CurrentDirectory
        )

    }
    catch [System.UnauthorizedAccessException] {

        $AccessDeniedCount++

        continue

    }
    catch [System.IO.IOException] {

        $IOErrorCount++

        continue

    }
    catch {

        $OtherErrorCount++

        continue

    }

    # --------------------------------------------------------
    # Process Child Directories
    # --------------------------------------------------------

    foreach ($Directory in $Directories) {

        # ----------------------------------------------------
        # Check directory attributes
        # ----------------------------------------------------

        try {

            $Attributes = [System.IO.File]::GetAttributes(
                $Directory
            )

        }
        catch [System.UnauthorizedAccessException] {

            $AccessDeniedCount++

            continue

        }
        catch [System.IO.IOException] {

            $IOErrorCount++

            continue

        }
        catch {

            $OtherErrorCount++

            continue

        }

        # ----------------------------------------------------
        # Skip Reparse Points
        # ----------------------------------------------------

        if (($Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {

            $ReparseCount++

            continue

        }

        # ----------------------------------------------------
        # Folder Match
        # ----------------------------------------------------

        if ($SearchType -eq "2" -or $SearchType -eq "3") {

            try {

                $DirectoryName = [System.IO.Path]::GetFileName(
                    $Directory.TrimEnd('\')
                )

                if ($DirectoryName -like $SearchPattern) {

                    $FoundCount++

                    Write-Host $Directory -ForegroundColor Yellow

                }

            }
            catch {

                $OtherErrorCount++

            }

        }

        # ----------------------------------------------------
        # Add directory to queue
        # ----------------------------------------------------

        $DirectoryQueue.Enqueue($Directory)

    }

    # --------------------------------------------------------
    # Lightweight progress
    # --------------------------------------------------------

    if (($DirectoriesScanned % 1000) -eq 0) {

        Write-Host "`rDirectories scanned: $DirectoriesScanned | Files scanned: $FilesScanned | Results: $FoundCount" -NoNewline

    }

}

# ============================================================
# Stop Timer
# ============================================================

$Stopwatch.Stop()

Write-Host ""
Write-Host ""

# ============================================================
# Search Summary
# ============================================================

Write-Host "==============================================" -ForegroundColor Green
Write-Host "                 SEARCH COMPLETE" -ForegroundColor Green
Write-Host "==============================================" -ForegroundColor Green
Write-Host ""

Write-Host "Results Found       : $FoundCount"
Write-Host "Directories Scanned : $DirectoriesScanned"
Write-Host "Files Scanned       : $FilesScanned"
Write-Host ""

Write-Host "Access Denied       : $AccessDeniedCount"
Write-Host "I/O Errors          : $IOErrorCount"
Write-Host "Reparse Points      : $ReparseCount"
Write-Host "Other Errors        : $OtherErrorCount"
Write-Host ""

Write-Host "Search Time         : $($Stopwatch.Elapsed.TotalSeconds.ToString("N3")) seconds"

Write-Host ""
Write-Host "==============================================" -ForegroundColor Green
Write-Host ""