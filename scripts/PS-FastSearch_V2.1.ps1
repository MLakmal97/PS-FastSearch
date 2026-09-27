<#
.SYNOPSIS
    PS-FastSearch - Hybrid File Search Utility

.DESCRIPTION
    Provides three search modes:

        Fast  - Windows Search Index
        Deep  - Direct filesystem search
        Auto  - Fast search with Deep Search fallback

    Supports:

        File
        Folder
        File + Folder

.AUTHOR
    Madhushanka Lakmal

.VERSION
    0.2.1
#>

# ============================================================
# Configuration
# ============================================================

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptRoot

$IndexedScript = Join-Path $ProjectRoot "src\Search-Indexed.ps1"
$DeepScript    = Join-Path $ProjectRoot "src\Search-Deep.ps1"

# ============================================================
# Validate Search Engines
# ============================================================

if (-not (Test-Path -LiteralPath $IndexedScript)) {

    Write-Host ""
    Write-Host "ERROR: Search-Indexed.ps1 not found." -ForegroundColor Red
    Write-Host $IndexedScript -ForegroundColor Red
    Write-Host ""

    exit
}

if (-not (Test-Path -LiteralPath $DeepScript)) {

    Write-Host ""
    Write-Host "ERROR: Search-Deep.ps1 not found." -ForegroundColor Red
    Write-Host $DeepScript -ForegroundColor Red
    Write-Host ""

    exit
}

# ============================================================
# Load Search Engines
# ============================================================

. $IndexedScript
. $DeepScript

# ============================================================
# Banner
# ============================================================

Clear-Host

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "              PS-FastSearch" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Version : 0.2.1"
Write-Host "Author  : Madhushanka Lakmal"
Write-Host ""
Write-Host "Fast + Deep File Search Utility"
Write-Host "============================================"
Write-Host ""

# ============================================================
# Search Mode
# ============================================================

Write-Host "Search Mode" -ForegroundColor Yellow
Write-Host ""

Write-Host "[1] Fast Search   - Windows Search Index"
Write-Host "[2] Deep Search   - Direct filesystem scan"
Write-Host "[3] Auto Search   - Fast + Deep fallback"
Write-Host ""

$ModeChoice = Read-Host "Select search mode"

switch ($ModeChoice) {

    "1" {
        $SearchMode = "Fast"
    }

    "2" {
        $SearchMode = "Deep"
    }

    "3" {
        $SearchMode = "Auto"
    }

    default {

        Write-Host ""
        Write-Host "Invalid search mode." -ForegroundColor Red
        Write-Host ""

        exit
    }
}

# ============================================================
# Search Type
# ============================================================

Write-Host ""
Write-Host "Search Type" -ForegroundColor Yellow
Write-Host ""

Write-Host "[1] File"
Write-Host "[2] Folder"
Write-Host "[3] File + Folder"
Write-Host ""

$TypeChoice = Read-Host "Select search type"

switch ($TypeChoice) {

    "1" {
        $SearchType = "File"
    }

    "2" {
        $SearchType = "Folder"
    }

    "3" {
        $SearchType = "Both"
    }

    default {

        Write-Host ""
        Write-Host "Invalid search type." -ForegroundColor Red
        Write-Host ""

        exit
    }
}

# ============================================================
# Search Path
# ============================================================

Write-Host ""

$SearchPath = Read-Host "Search path [C:\]"

if ([string]::IsNullOrWhiteSpace($SearchPath)) {

    $SearchPath = "C:\"
}

if (-not (Test-Path -LiteralPath $SearchPath)) {

    Write-Host ""
    Write-Host "Path does not exist:" -ForegroundColor Red
    Write-Host $SearchPath -ForegroundColor Red
    Write-Host ""

    exit
}

# ============================================================
# Search Name
# ============================================================

Write-Host ""

$SearchName = Read-Host "Search name"

if ([string]::IsNullOrWhiteSpace($SearchName)) {

    Write-Host ""
    Write-Host "Search name cannot be empty." -ForegroundColor Red
    Write-Host ""

    exit
}

# ============================================================
# Display Configuration
# ============================================================

Write-Host ""
Write-Host "============================================" -ForegroundColor DarkGray
Write-Host "Search Configuration" -ForegroundColor Cyan
Write-Host "============================================"

Write-Host "Mode : $SearchMode"
Write-Host "Type : $SearchType"
Write-Host "Path : $SearchPath"
Write-Host "Name : $SearchName"

Write-Host "============================================"
Write-Host ""

# ============================================================
# Execute Search
# ============================================================

$OverallTimer = [System.Diagnostics.Stopwatch]::StartNew()

$ResultList = @()
$SearchStatistics = $null
$ActualSearchEngine = $null

try {

    switch ($SearchMode) {

        # ======================================================
        # FAST SEARCH
        # ======================================================

        "Fast" {

            Write-Host "Running Fast Search..." -ForegroundColor Yellow
            Write-Host ""

            $FastResult = Search-Indexed `
                -Path $SearchPath `
                -Name $SearchName `
                -Type $SearchType

            $ResultList = @($FastResult.Results)

            $SearchStatistics = $FastResult.Statistics

            $ActualSearchEngine = "Windows Search Index"
        }

        # ======================================================
        # DEEP SEARCH
        # ======================================================

        "Deep" {

            Write-Host "Running Deep Search..." -ForegroundColor Yellow
            Write-Host ""

            $DeepResult = Search-Deep `
                -Path $SearchPath `
                -Name $SearchName `
                -Type $SearchType

            $ResultList = @($DeepResult.Results)

            $SearchStatistics = $DeepResult.Statistics

            $ActualSearchEngine = "Filesystem"
        }

        # ======================================================
        # AUTO SEARCH
        # ======================================================

        "Auto" {

            Write-Host "Running Auto Search..." -ForegroundColor Yellow
            Write-Host ""

            # --------------------------------------------------
            # First attempt: Windows Search Index
            # --------------------------------------------------

            Write-Host "Trying Windows Search Index..." `
                -ForegroundColor DarkCyan

            try {

                $FastResult = Search-Indexed `
                    -Path $SearchPath `
                    -Name $SearchName `
                    -Type $SearchType

                $FastResults = @($FastResult.Results)

                # ------------------------------------------------
                # Indexed results found
                # ------------------------------------------------

                if ($FastResults.Count -gt 0) {

                    $ResultList = $FastResults

                    $SearchStatistics = $FastResult.Statistics

                    $ActualSearchEngine = "Windows Search Index"

                    Write-Host ""
                    Write-Host "Indexed results found." `
                        -ForegroundColor Green
                }

                # ------------------------------------------------
                # No indexed results
                # ------------------------------------------------

                else {

                    Write-Host ""
                    Write-Host "No indexed results found." `
                        -ForegroundColor Yellow

                    Write-Host "Falling back to Deep Search..." `
                        -ForegroundColor Yellow

                    Write-Host ""

                    $DeepResult = Search-Deep `
                        -Path $SearchPath `
                        -Name $SearchName `
                        -Type $SearchType

                    $ResultList = @($DeepResult.Results)

                    $SearchStatistics = $DeepResult.Statistics

                    $ActualSearchEngine = "Filesystem (Deep Fallback)"
                }
            }

            catch {

                Write-Host ""
                Write-Host "Windows Search Index unavailable." `
                    -ForegroundColor Yellow

                Write-Host "Falling back to Deep Search..." `
                    -ForegroundColor Yellow

                Write-Host ""

                $DeepResult = Search-Deep `
                    -Path $SearchPath `
                    -Name $SearchName `
                    -Type $SearchType

                $ResultList = @($DeepResult.Results)

                $SearchStatistics = $DeepResult.Statistics

                $ActualSearchEngine = "Filesystem (Deep Fallback)"
            }
        }
    }
}

catch {

    Write-Host ""
    Write-Host "============================================" `
        -ForegroundColor Red

    Write-Host "SEARCH ERROR" -ForegroundColor Red

    Write-Host "============================================" `
        -ForegroundColor Red

    Write-Host ""

    Write-Host $_.Exception.Message -ForegroundColor Red

    Write-Host ""

    exit
}

$OverallTimer.Stop()

# ============================================================
# Search Results
# ============================================================

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Search Results" -ForegroundColor Cyan
Write-Host "============================================"

Write-Host ""

if ($ResultList.Count -eq 0) {

    Write-Host "No results found." -ForegroundColor Yellow
}

else {

    $ResultList |
        Format-Table `
            Path,
            Name,
            Type,
            Size,
            DateModified `
            -AutoSize
}

# ============================================================
# Statistics
# ============================================================

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Search Statistics" -ForegroundColor Cyan
Write-Host "============================================"

Write-Host "Search Engine : $ActualSearchEngine"
Write-Host "Results Found : $($ResultList.Count)"
Write-Host "Total Time    : $($OverallTimer.Elapsed.TotalSeconds.ToString("N3")) seconds"

# ============================================================
# Deep Search Statistics
# ============================================================

if ($SearchMode -eq "Deep" -or
    $ActualSearchEngine -eq "Filesystem (Deep Fallback)") {

    Write-Host ""
    Write-Host "Deep Search Statistics" -ForegroundColor DarkCyan

    Write-Host "Directories   : $($SearchStatistics.DirectoriesScanned)"
    Write-Host "Files         : $($SearchStatistics.FilesScanned)"
    Write-Host "Access Denied : $($SearchStatistics.AccessDenied)"
    Write-Host "I/O Errors    : $($SearchStatistics.IOErrorCount)"
    Write-Host "Reparse Points: $($SearchStatistics.ReparsePoints)"
}

# ============================================================
# Fast Search Statistics
# ============================================================

if ($ActualSearchEngine -eq "Windows Search Index") {

    Write-Host ""
    Write-Host "Indexed Search Statistics" -ForegroundColor DarkCyan

    Write-Host "Search Time   : $($SearchStatistics.SearchTimeSeconds) seconds"
    Write-Host "Search Type   : $($SearchStatistics.SearchType)"
}

Write-Host "============================================"
Write-Host ""

Read-Host "Press ENTER to exit"