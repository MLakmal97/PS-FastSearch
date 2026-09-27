# PS-FastSearch

A PowerShell-based filesystem search utility for Windows, designed to provide fast indexed searching and reliable deep filesystem searching.

## Version

**0.2.2**

## Author

**Madhushanka Lakmal**

---

## Overview

PS-FastSearch provides three search modes:

1. **Fast Search** — Uses the Windows Search Index for very fast searches.
2. **Deep Search** — Traverses the filesystem directly for a more complete search.
3. **Auto Search** — Attempts the Windows Search Index first and falls back to Deep Search when no indexed results are found.

The project is designed as a practical PowerShell administration tool and is being developed incrementally from a simple search utility toward a production-quality Windows administration toolkit.

---

## Features

- Fast indexed file search
- Fast indexed folder search
- Fast indexed file + folder search
- Deep filesystem search
- Automatic search mode
- File / Folder / Both search types
- Structured search statistics
- Search path validation
- Error handling
- Access-denied handling in Deep Search
- Reparse-point handling
- Queue-based filesystem traversal
- Clear distinction between indexed and complete search results

---

## Search Modes

### 1. Fast Search

Fast Search uses the **Windows Search Index**.

```text
Fast Search
    |
    v
Windows Search Index
    |
    +-- File
    +-- Folder
    +-- Both
```

Advantages:

- Extremely fast
- Suitable for frequently indexed locations
- Useful for interactive searches

Important:

> Fast Search only returns items available through the Windows Search index. It does not guarantee complete filesystem coverage.

---

### 2. Deep Search

Deep Search performs direct filesystem traversal.

```text
Deep Search
    |
    v
Filesystem
    |
    v
Queue-based traversal
    |
    +-- Files
    +-- Folders
```

Advantages:

- Searches the filesystem directly
- Designed for complete filesystem searches
- Handles large directory trees using iterative queue-based traversal
- Handles access-denied directories and filesystem errors without terminating the entire search

Deep Search is slower than Fast Search because it has to inspect the filesystem rather than query an existing index.

---

### 3. Auto Search

Auto Search attempts the Windows Search Index first.

```text
Auto Search
    |
    v
Windows Search Index
    |
    +-- Results found --> Return indexed results
    |
    +-- No results -----> Deep Search
```

This provides a balance between speed and search coverage.

Fast results are returned when the index contains matching items. If no indexed results are found, the application can fall back to Deep Search.

The returned result always identifies whether the search result is **Indexed** or **Complete**.

---

## Search Types

PS-FastSearch supports three search types:

```text
[1] File
[2] Folder
[3] File + Folder
```

### File

Searches for files matching the supplied name.

### Folder

Searches for directories/folders matching the supplied name.

### Both

Searches for both files and folders.

---

## Project Structure

```text
PS-FastSearch
│
├── scripts
│   ├── PS-FastSearch.ps1
│   └── PS-FastSearch_V1.2.ps1
│
├── src
│   ├── Search-Deep.ps1
│   └── Search-Indexed.ps1
│
├── .gitignore
└── README.md
```

### scripts

Contains the main application launcher and related application scripts.

### src

Contains the individual search engines used by PS-FastSearch.

- `Search-Indexed.ps1` — Windows Search Index engine
- `Search-Deep.ps1` — Direct filesystem search engine

---

## Requirements

- Windows
- Windows PowerShell 5.1 or PowerShell 7+
- Windows Search service for Fast Search
- Appropriate permissions for directories being searched

---

## Running the Application

Clone or download the repository and open PowerShell in the project directory.

```powershell
Set-Location "PS-FastSearch"
```

Run:

```powershell
.\scripts\PS-FastSearch.ps1
```

The application will display the interactive menu:

```text
============================================
              PS-FastSearch
============================================

Search Mode

[1] Fast Search   - Windows Search Index
[2] Deep Search   - Direct filesystem scan
[3] Auto Search   - Windows Search Index first
```

---

## Example

Example search:

```text
Search Mode: Fast
Search Type: File
Path: C:\
Name: report
```

Example indexed results:

```text
C:\Users\Lakmal\Downloads\CCNA_Static_Routing_Lab_Report_Template.docx
C:\Users\Lakmal\Downloads\SPSS Report.pdf
```

---

## Search Statistics

PS-FastSearch returns structured statistics including:

```text
ResultsFound
SearchTimeSeconds
SearchType
SearchPath
SearchEngine
SearchScope
Completeness
```

Example:

```text
ResultsFound      : 2
SearchTimeSeconds : 0.081
SearchType        : File
SearchPath        : C:\
SearchEngine      : Windows Search Index
SearchScope       : Indexed items only
Completeness      : Indexed
```

---

## Performance

The project was developed with performance as an important requirement.

A baseline PowerShell recursive search was benchmarked against the queue-based Deep Search engine.

### Baseline

```powershell
Measure-Command {
    Get-ChildItem -Path C:\ -File -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like "*report*" }
}
```

Baseline measurement:

```text
~349.6 seconds
```

A queue-based Deep Search implementation subsequently reduced the measured runtime substantially in testing.

Example measured Deep Search:

```text
~106.6 seconds
```

Actual runtime depends on:

- Filesystem size
- Number of directories
- Disk performance
- Access permissions
- Reparse points
- Running processes
- Windows filesystem state

Benchmarks are environment-specific and should not be interpreted as universal performance guarantees.

---

## Indexed Search vs Deep Search

| Feature | Fast Search | Deep Search |
|---|---|---|
| Search engine | Windows Search Index | Filesystem |
| Speed | Very fast | Slower |
| Indexed items | Yes | Not required |
| Direct filesystem traversal | No | Yes |
| File search | Yes | Yes |
| Folder search | Yes | Yes |
| Both | Yes | Yes |
| Complete filesystem coverage | No guarantee | Designed for complete search |
| Best use | Fast interactive search | Thorough search |

---

## Why Two Search Engines?

Windows Search provides very fast results because it queries an existing search index.

However, indexed search does not guarantee that every filesystem item is indexed.

Deep Search solves this by directly traversing the filesystem.

This gives PS-FastSearch two different strengths:

```text
FAST
Speed
  |
  v
Windows Search Index


DEEP
Coverage
  |
  v
Filesystem traversal
```

---

## Development Roadmap

### V0.2.2 — Current

- [x] Interactive search menu
- [x] Fast indexed search
- [x] Deep filesystem search
- [x] File search
- [x] Folder search
- [x] File + Folder search
- [x] Auto Search
- [x] Structured statistics
- [x] Access-denied handling
- [x] Reparse-point handling
- [x] Queue-based traversal
- [x] Indexed/complete result labeling

### Future

Potential future development includes:

- [ ] Extension filters
- [ ] File size filters
- [ ] Date filters
- [ ] Progress display
- [ ] Result export
- [ ] CSV export
- [ ] JSON export
- [ ] Open result directly
- [ ] Copy result path
- [ ] PowerShell pipeline support
- [ ] Improved hybrid search
- [ ] Automated tests
- [ ] Performance benchmark suite
- [ ] Production documentation
- [ ] Release automation

---

## PowerShell Learning Goals

This project is also being developed as a practical PowerShell learning project.

Topics demonstrated by the project include:

- Functions
- Parameters
- Validation attributes
- Objects
- Custom objects
- Error handling
- `try/catch/finally`
- File and directory operations
- .NET classes
- Generic collections
- Queues
- Windows Search OLE DB
- SQL-like queries
- Stopwatch-based benchmarking
- Script modularization
- Dot-sourcing
- Project-relative paths
- Git version control

---

## Versioning

The project uses version tags such as:

```text
v0.2.2
```

Example:

```powershell
git tag -a v0.2.2 -m "PS-FastSearch v0.2.2"
git push origin v0.2.2
```

---

## Disclaimer

PS-FastSearch is an evolving administration and learning project.

Search completeness and performance depend on the Windows environment, filesystem permissions, Windows Search indexing configuration, storage performance, and other system conditions.

Always validate results before using the tool for critical administrative or forensic purposes.

---

## Author

**Madhushanka Lakmal**

PowerShell | Windows Administration | IT Operations | Automation
