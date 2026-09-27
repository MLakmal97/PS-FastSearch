# Contributing to PS-FastSearch

Thank you for your interest in contributing to PS-FastSearch.

## Development workflow

1. Fork the repository.
2. Clone your fork.
3. Create a feature branch.
4. Make focused changes.
5. Test the PowerShell code.
6. Update documentation when needed.
7. Commit your changes with a clear message.
8. Push the branch.
9. Open a Pull Request.

Example:

```powershell
git checkout -b feature/add-extension-filter
```

## PowerShell guidelines

- Use clear function and parameter names.
- Follow approved PowerShell verb naming where applicable.
- Prefer readable code over unnecessarily clever code.
- Handle errors explicitly.
- Avoid hard-coded credentials or secrets.
- Do not collect or transmit user filesystem data externally.
- Keep administrative privileges to the minimum required.
- Update README documentation when command behavior changes.

## Commit message examples

```text
Add extension filtering
Fix deep search permission handling
Improve indexed search performance
Update installation documentation
Add initial Pester tests
```

## Security

Never commit:

- Passwords
- API keys
- Certificates/private keys
- Credential XML files
- Internal configuration containing secrets
- Sensitive production data
