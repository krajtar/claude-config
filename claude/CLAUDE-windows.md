
## WSL Environment
- When the user provides a Windows file path (e.g., `C:\Users\...\file.png`), translate it to WSL form (`/mnt/c/Users/.../file.png`) and read it directly
- When creating or editing shell scripts, always use LF line endings — never CRLF. If a script fails with `\r` errors, fix line endings with `sed -i 's/\r$//'`
- Be aware that files edited in Windows editors (Notepad, VS Code with default settings) may have CRLF line endings. When debugging mysterious parse errors, check for `\r` characters first
- Git may be configured with `core.autocrlf=true` on Windows. When troubleshooting git diff issues or unexpected changes, check this setting
