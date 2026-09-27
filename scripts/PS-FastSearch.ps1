<#
.SYNOPSIS
    PS-FastSearch - Fast and Deep filesystem search utility.

.DESCRIPTION
    Provides three search modes:

    1. Fast Search
       Uses Windows Search Index.
       Searches indexed items only.

    2. Deep Search
       Performs a direct filesystem traversal.
       Designed for complete filesystem searches.

    3. Auto Search
       Attempts Windows Search Index first.
       Clearly reports that indexed results are not complete filesystem results.

.AUTHOR
    Madhushanka Lakmal

.VERSION
    0.2.2
#>

Clear-Host

# ============================================================
# Configuration
# ============================================================

$Version = "0.2.2"
$Author  = "Madhushanka Lakmal"

$ScriptRoot  = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptRoot

$IndexedScript = Join-Path $ProjectRoot "src\Search-Indexed.ps1"
$DeepScript    = Join-Path $ProjectRoot "src\Search-Deep.ps1"

# ============================================================
# Validate engine scripts
# ============================================================

if (-not (Test-Path $IndexedScript)) {
    Write-Host ""
    Write-Host "ERROR: Search-Indexed.ps1 not found." -ForegroundColor Red
    Write-Host $IndexedScript -ForegroundColor Yellow
    exit 1
}

if (-not (Test-Path $DeepScript)) {
    Write-Host ""
    Write-Host "ERROR: Search-Deep.ps1 not found." -ForegroundColor Red
    Write-Host $DeepScript -ForegroundColor Yellow
    exit 1
}

# ============================================================
# Load search engines
# ============================================================

. $IndexedScript
. $DeepScript

# ============================================================
# Banner
# ============================================================

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "              PS-FastSearch" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Version : $Version"
Write-Host "Author  : $Author"
Write-Host ""

# ============================================================
# Search Mode
# ============================================================

Write-Host "Search Mode" -ForegroundColor Yellow
Write-Host ""
Write-Host "[1] Fast Search   - Windows Search Index"
Write-Host "[2] Deep Search   - Direct filesystem scan"
Write-Host "[3] Auto Search   - Windows Search Index first"
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
        exit 1
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
        exit 1
    }
}

# ============================================================
# Search Path
# ============================================================

Write-Host ""

$SearchPath = Read-Host "Enter search path [C:\]"

if ([string]::IsNullOrWhiteSpace($SearchPath)) {
    $SearchPath = "C:\"
}

# ============================================================
# Search Name
# ============================================================

$SearchName = Read-Host "Enter search name"

if ([string]::IsNullOrWhiteSpace($SearchName)) {

    Write-Host ""
    Write-Host "Search name cannot be empty." -ForegroundColor Red

    exit 1
}

# ============================================================
# Display configuration
# ============================================================

Write-Host ""
Write-Host "============================================" -ForegroundColor DarkCyan
Write-Host "              SEARCH CONFIGURATION" -ForegroundColor DarkCyan
Write-Host "============================================" -ForegroundColor DarkCyan

Write-Host "Mode       : $SearchMode"
Write-Host "Type       : $SearchType"
Write-Host "Path       : $SearchPath"
Write-Host "Name       : $SearchName"

Write-Host "============================================" -ForegroundColor DarkCyan
Write-Host ""

# ============================================================
# Application Timer
# ============================================================

$ApplicationStopwatch = [System.Diagnostics.Stopwatch]::StartNew()

$SearchResult = $null
$SearchEngine = $null
$SearchScope = $null
$Completeness = $null

# ============================================================
# FAST SEARCH
# ============================================================

if ($SearchMode -eq "Fast") {

    Write-Host "Searching Windows Search Index..." -ForegroundColor Cyan
    Write-Host ""

    try {

        $SearchResult = Search-Indexed `
            -Path $SearchPath `
            -Name $SearchName `
            -Type $SearchType

        $SearchEngine = "Windows Search Index"
        $SearchScope = "Indexed items only"
        $Completeness = "Indexed"

    }
    catch {

        Write-Host ""
        Write-Host "Fast Search failed." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red

        exit 1
    }
}

# ============================================================
# DEEP SEARCH
# ============================================================

elseif ($SearchMode -eq "Deep") {

    Write-Host "Searching filesystem..." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "This may take some time for large drives." -ForegroundColor Yellow
    Write-Host ""

    try {

        $SearchResult = Search-Deep `
            -Path $SearchPath `
            -Name $SearchName `
            -Type $SearchType

        $SearchEngine = "Filesystem"
        $SearchScope = "Direct filesystem traversal"
        $Completeness = "Complete"

    }
    catch {

        Write-Host ""
        Write-Host "Deep Search failed." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red

        exit 1
    }
}

# ============================================================
# AUTO SEARCH
# ============================================================

elseif ($SearchMode -eq "Auto") {

    Write-Host "Trying Windows Search Index..." -ForegroundColor Cyan
    Write-Host ""

    try {

        $SearchResult = Search-Indexed `
            -Path $SearchPath `
            -Name $SearchName `
            -Type $SearchType

        if ($null -ne $SearchResult -and
            $null -ne $SearchResult.Results -and
            $SearchResult.Results.Count -gt 0) {

            Write-Host "Indexed results found." -ForegroundColor Green
            Write-Host ""

            $SearchEngine = "Windows Search Index"
            $SearchScope = "Indexed items only"
            $Completeness = "Indexed"

        }
        else {

            Write-Host "No indexed results found." -ForegroundColor Yellow
            Write-Host "Falling back to Deep Search..." -ForegroundColor Yellow
            Write-Host ""

            $SearchResult = Search-Deep `
                -Path $SearchPath `
                -Name $SearchName `
                -Type $SearchType

            $SearchEngine = "Filesystem"
            $SearchScope = "Direct filesystem traversal"
            $Completeness = "Complete"
        }

    }
    catch {

        Write-Host ""
        Write-Host "Windows Search Index failed." -ForegroundColor Yellow
        Write-Host "Falling back to Deep Search..." -ForegroundColor Yellow
        Write-Host ""

        try {

            $SearchResult = Search-Deep `
                -Path $SearchPath `
                -Name $SearchName `
                -Type $SearchType

            $SearchEngine = "Filesystem"
            $SearchScope = "Direct filesystem traversal"
            $Completeness = "Complete"

        }
        catch {

            Write-Host ""
            Write-Host "Auto Search failed." -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red

            exit 1
        }
    }
}

# ============================================================
# Stop application timer
# ============================================================

$ApplicationStopwatch.Stop()

$TotalTime = [math]::Round(
    $ApplicationStopwatch.Elapsed.TotalSeconds,
    3
)

# ============================================================
# Extract results
# ============================================================

$Results = @()

if ($null -ne $SearchResult -and $null -ne $SearchResult.Results) {

    $Results = @($SearchResult.Results)
}

$ResultsFound = $Results.Count

# ============================================================
# Search Summary
# ============================================================

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "              SEARCH SUMMARY" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

Write-Host "Search Engine : $SearchEngine"
Write-Host "Search Scope  : $SearchScope"
Write-Host "Search Type   : $SearchType"
Write-Host "Results Found : $ResultsFound"
Write-Host "Total Time    : $TotalTime seconds"
Write-Host "Completeness  : $Completeness"

Write-Host "============================================" -ForegroundColor Cyan

# ============================================================
# Indexed Search Warning
# ============================================================

if ($Completeness -eq "Indexed") {

    Write-Host ""
    Write-Host "NOTE:" -ForegroundColor Yellow
    Write-Host "Fast Search uses the Windows Search index." -ForegroundColor Yellow
    Write-Host "Results may not include unindexed files or folders." -ForegroundColor Yellow
    Write-Host "Use Deep Search for a complete filesystem search." -ForegroundColor Yellow
}

# ============================================================
# Search Results
# ============================================================

Write-Host ""

if ($ResultsFound -gt 0) {

    Write-Host "============================================" -ForegroundColor Green
    Write-Host "              SEARCH RESULTS" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green

    $Results |
        Select-Object Path, Name, Type, Size, DateModified |
        Format-Table -AutoSize

}
else {

    Write-Host "No matching results found." -ForegroundColor Yellow
}

# ============================================================
# Deep Search Statistics
# ============================================================

if ($SearchEngine -eq "Filesystem" -and
    $null -ne $SearchResult.Statistics) {

    Write-Host ""
    Write-Host "============================================" -ForegroundColor DarkCyan
    Write-Host "          DEEP SEARCH STATISTICS" -ForegroundColor DarkCyan
    Write-Host "============================================" -ForegroundColor DarkCyan

    $SearchResult.Statistics |
        Format-List
}

# ============================================================
# Indexed Search Statistics
# ============================================================

if ($SearchEngine -eq "Windows Search Index" -and
    $null -ne $SearchResult.Statistics) {

    Write-Host ""
    Write-Host "============================================" -ForegroundColor DarkCyan
    Write-Host "       INDEXED SEARCH STATISTICS" -ForegroundColor DarkCyan
    Write-Host "============================================" -ForegroundColor DarkCyan

    $SearchResult.Statistics |
        Format-List
}

Write-Host ""
Write-Host "PS-FastSearch completed." -ForegroundColor Green