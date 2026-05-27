# Release Notes Updater

A Bash script that generates categorised, Markdown-formatted release notes from your Git history — grouping commits by type and supporting tagged releases as well as unreleased changes.

---

## Requirements

- Bash 4.0+ (`mapfile` / associative arrays)
- Git

---

## Installation

Copy `scripts/update-release-notes.sh` into your project and make it executable:

```bash
chmod +x scripts/update-release-notes.sh
```

---

## Usage

```bash
# Full release notes (all tags), unreleased section labelled "Latest"
./scripts/update-release-notes.sh > release.md

# Label the unreleased section with an upcoming version
./scripts/update-release-notes.sh -untagged v1.2.6 > release.md

# Only include the last 10 tags (plus the unreleased section)
./scripts/update-release-notes.sh -limit 10 > release.md

# Combined
./scripts/update-release-notes.sh -untagged v1.2.6 -limit 10 > release.md
```

### Options

| Option | Description |
|---|---|
| `-untagged <label>` | Label for the unreleased (untagged) section at the top. Defaults to `Latest`. |
| `-limit <n>` | Only include the most recent `n` tagged releases. Without this flag, all tags are included. |

---

## How It Works

1. **Unreleased section** — collects all commits between the latest tag and `HEAD`, always shown at the top.
2. **Tagged sections** — iterates tags newest-first, printing commits between each consecutive tag pair.
3. **Categorisation** — each commit message is matched against a known prefix (after stripping an optional leading JIRA key such as `KWOS-123`) and placed into the appropriate sub-section.

### Commit Prefix → Category Mapping

| Commit prefix | Section |
|---|---|
| `feat:` | Features |
| `fix:` | Bug Fixes |
| `improv:` / `improvement:` / `improvements:` | Improvements |
| `enhance:` | Enhancements |
| `opt:` | Optimisations |
| `adj:` | Adjustments |
| *(no recognised prefix)* | Others |

Matching is case-insensitive. JIRA-style prefixes (e.g. `KWOS-123 feat: ...`) are handled automatically.

---

## Example Output

```markdown
## v1.2.6 (2026-05-27)

### Features

*  JIRA-123 feat: Panic feature for Food Scarcity mode [View](https://...)
*  JIRA-456 feat: Punch mechanic updates [View](https://...)

### Bug Fixes

*  JIRA-789 fix: Disrespect button causes mayhem [View](https://...)

### Optimisations

*  JIRA-890 opt: House cleaning integrates with automation [View](https://...)

### Others

*  Fix issue where the friend never pays back what he owes you [View](https://...)


## v1.2.5r11 (2026-05-21)

### Bug Fixes

*  JIRA-012 fix: Problematic neighbour running towards you [View](https://...)
```

## Support & Contact

- **GitHub**: https://github.com/pmavila
- **Hire me**: https://www.linkedin.com/in/paulo-miguel-avila/
- **Buy me a coffee**: https://www.paypal.me/webpoga

---

## License

GNU General Public License v3.0 (GPLv3) — see https://www.gnu.org/licenses/gpl-3.0.html

