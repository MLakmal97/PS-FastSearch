# PS-FastSearch

Fast, flexible file and folder search for Windows PowerShell.

**PS-FastSearch** is a PowerShell-based search utility designed for system administrators, IT support engineers, and Windows power users who need a simple way to locate files and folders quickly.

It supports multiple search strategies:

- **Fast Search** — Uses the Windows Search index for speed.
- **Deep Search** — Scans the filesystem directly when indexed search is not enough.
- **Auto Search** — Tries indexed search first and can fall back to deeper searching.

---

## Project Information

| Item | Details |
|---|---|
| Project | PS-FastSearch |
| Version | 0.2.2 |
| Author | Madhushanka Lakmal |
| Platform | Windows |
| Language | PowerShell |
| PowerShell | Windows PowerShell 5.1+ |
| Status | Development / Early Release |

---

## Features

### Search Modes

#### 1. Fast Search

Uses the Windows Search index.

Best when:

- Searching normal user files
- Windows Search indexing is enabled
- You need quick results

#### 2. Deep Search

Performs a direct filesystem scan.

Best when:

- A file is not indexed
- Searching locations excluded from indexing
- You need a more complete filesystem search

> Deep search can be significantly slower on large drives.

#### 3. Auto Search

Automatically attempts the faster indexed search method first.

This is intended to become the recommended mode for normal usage.

---

## Search Types

PS-FastSearch supports:

- File search
- Folder search

Example:

```powershell
Search-Indexed -Path "C:\" -Name "report"
```

---

## Project Structure

```text
PS-FastSearch/
│
├── README.md
├── LICENSE
├── .gitignore
│
├── src/
│   ├── Search-Indexed.ps1
│   ├── Search-Deep.ps1
│   └── Search-Auto.ps1
│
├── tests/
│   └──
│
├── docs/
│   └──
│
└── examples/
    └──
```

The project structure may change as development continues.

---

# Requirements

## Operating System

Supported target platform:

- Windows 10
- Windows 11
- Windows Server

## PowerShell

Recommended:

- Windows PowerShell 5.1+
- PowerShell 7+ may be supported depending on the individual search implementation

Check your PowerShell version:

```powershell
$PSVersionTable.PSVersion
```

---

# Installation

## Option 1 — Clone with Git

Clone the repository:

```powershell
git clone https://github.com/MLakmal97/PS-FastSearch.git
```

Move into the project:

```powershell
cd PS-FastSearch
```

---

## Option 2 — Download ZIP

Download the repository as a ZIP file from GitHub and extract it.

Then open PowerShell in the project directory.

---

# Running the Project

If the project contains a main script, run it using:

```powershell
.\PS-FastSearch.ps1
```

If the script is located elsewhere, use its full path:

```powershell
& "D:\PS-FastSearch\PS-FastSearch.ps1"
```

If you need to run a specific source script:

```powershell
& "D:\PS-FastSearch\src\Search-Indexed.ps1"
```

---

# Using the Search Function

If `Search-Indexed.ps1` defines the `Search-Indexed` function, load it into the current PowerShell session:

```powershell
. "D:\PS-FastSearch\src\Search-Indexed.ps1"
```

Then run:

```powershell
Search-Indexed -Path "C:\" -Name "report"
```

Another example:

```powershell
Search-Indexed -Path "D:\" -Name "backup"
```

---

# PowerShell Execution Policy

If PowerShell blocks script execution, check the current policy:

```powershell
Get-ExecutionPolicy -List
```

For a script downloaded from the Internet, you may need to unblock it:

```powershell
Unblock-File ".\PS-FastSearch.ps1"
```

Do not blindly change the system-wide execution policy. Prefer the least-privileged approach appropriate for your environment.

---

# Development

## Clone the Repository

```powershell
git clone https://github.com/MLakmal97/PS-FastSearch.git
cd PS-FastSearch
```

## Create a Development Branch

```powershell
git checkout -b feature/new-search-method
```

Make your changes and test them.

Check the changes:

```powershell
git status
```

Review the diff:

```powershell
git diff
```

---

# Git Workflow

A simple workflow for this project:

```text
Pull
  ↓
Create Branch
  ↓
Develop
  ↓
Test
  ↓
Commit
  ↓
Push
  ↓
Pull Request
  ↓
Merge
```

Example:

```powershell
git pull origin main

git checkout -b feature/improve-search

# Make changes

git status
git add .
git commit -m "Improve search performance"
git push -u origin feature/improve-search
```

---

# Updating an Existing Version

After making changes:

```powershell
git status
git add .
git commit -m "Update PS-FastSearch"
git push
```

For a release version:

```powershell
git tag v0.2.2
git push origin v0.2.2
```

Future releases can use:

```text
v0.2.3
v0.3.0
v1.0.0
```

---

# Recommended Versioning

PS-FastSearch follows semantic-style versioning:

```text
MAJOR.MINOR.PATCH
```

Example:

```text
1.2.3
│ │ │
│ │ └── Bug fixes
│ └──── New features
└────── Major breaking changes
```

---

# Security Considerations

PS-FastSearch is intended to run locally on Windows systems.

The project should not:

- Upload searched filenames to an external server
- Send filesystem information to a third party
- Store user search results remotely
- Require unnecessary administrator privileges
- Modify files during a normal search operation

Future features should preserve a local-first design.

---

# Performance Notes

Search performance depends on:

- Drive size
- Number of files
- Windows Search index status
- File permissions
- Network paths
- Disk performance
- Search method

For large drives, indexed search should generally be preferred when the required content is indexed.

Deep filesystem scanning can take considerably longer.

---

# Troubleshooting

## Search returns no results

Check whether Windows Search is running:

```powershell
Get-Service WSearch
```

Check the service status:

```powershell
Get-Service WSearch | Select-Object Name, Status, StartType
```

If indexed search does not find the file, try Deep Search.

---

## Access Denied

Some directories require elevated permissions.

If appropriate for your administrative task, open PowerShell as Administrator and retry.

Avoid running with elevated privileges unless required.

---

## Script execution is blocked

Check:

```powershell
Get-ExecutionPolicy -List
```

For an individual downloaded script:

```powershell
Unblock-File ".\script.ps1"
```

---

# Roadmap

Planned improvements:

- [ ] Improved CLI interface
- [ ] File extension filtering
- [ ] Folder-only filtering
- [ ] Multiple search paths
- [ ] Case-sensitive search option
- [ ] Regular expression search
- [ ] Search result export
- [ ] CSV output
- [ ] JSON output
- [ ] Search result statistics
- [ ] Better error handling
- [ ] Permission-aware search
- [ ] Search progress indicator
- [ ] Performance optimization
- [ ] Pester test coverage
- [ ] PowerShell module support
- [ ] Installable PowerShell module
- [ ] GitHub Actions CI
- [ ] Production release v1.0.0

---

# Example Future CLI

The long-term goal is to provide a simple command-line experience such as:

```powershell
PS-FastSearch -Path "C:\" -Name "report" -Mode Auto
```

Possible future examples:

```powershell
PS-FastSearch -Path "D:\Reports" -Name "*.pdf"

PS-FastSearch -Path "C:\Users" -Name "invoice" -Type File

PS-FastSearch -Path "D:\" -Name "Projects" -Type Folder -Mode Deep
```

These interfaces are part of the roadmap and may not be available in the current release.

---

# Contributing

Contributions are welcome.

Before submitting changes:

1. Create a feature branch.
2. Keep changes focused.
3. Test the PowerShell code.
4. Update documentation when behavior changes.
5. Use clear commit messages.
6. Submit a pull request.

Example:

```powershell
git checkout -b feature/add-json-output
```

---

# Author

**Madhushanka Lakmal**

IT System Administration | Windows | PowerShell | Automation | Infrastructure

GitHub:

https://github.com/MLakmal97

---

# License

This project is currently under development.

Add an appropriate open-source license before distributing the project publicly for reuse. A common choice for PowerShell utilities is the MIT License.

---

## Disclaimer

PS-FastSearch is provided as a development project and should be tested in a non-production environment before being used as part of operational workflows.

Always verify search results before performing administrative actions based on them.

---

## ⭐ Support the Project

If you find PS-FastSearch useful:

- ⭐ Star the repository
- 🐛 Report bugs
- 💡 Suggest improvements
- 🔧 Submit pull requests
- 📚 Share the project with other PowerShell administrators

---

**PS-FastSearch — Fast, practical filesystem search for Windows administrators.**
