# Local configuration example

Copy this directory to `config/local/` and edit files there for local/private configuration.
Do not commit real emails or secrets from `config/local/`.

## writers.txt

`writers.txt` controls who can edit documents.

- Add one allowed writer email per line.
- Blank lines are ignored.
- Lines starting with `#` or `//` are ignored.
- Email matching is case-insensitive.
