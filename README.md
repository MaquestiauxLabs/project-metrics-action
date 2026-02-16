# Project Metrics Action

A GitHub Action that automatically collects and displays project metrics from GitHub Projects v2 data in README files.

## Features

- **Project Status Tracking**: Monitors task status (Todo, In Progress, Done) across all GitHub Projects v2
- **Visual Badges**: Generates status badges and completion rate indicators
- **Language Statistics**: Tracks programming language usage across your organization
- **Automatic README Updates**: Injects metrics directly into designated README sections

## How It Works

The action fetches data from your organization's GitHub Projects v2, analyzes project statuses and repository languages, then injects formatted metrics into your README using AWK-based templates.

## Usage

### CLI

```bash
# Fetch project data
./scripts/get_data.sh <org> [output_path]

# Generate README from template
./scripts/update_readme.sh <data_path> <template_path> <output_path>
```

Example:

```bash
./scripts/get_data.sh MyOrg
./scripts/update_readme.sh data/projects.json sample-README.md data/README.md
```

### Basic Setup

1. **Add to Workflow**: Create `.github/workflows/metrics.yml`:

```yaml
name: Update Project Metrics

on:
  schedule:
    - cron: "0 */6 * * *" # Every 6 hours
  workflow_dispatch:

jobs:
  metrics:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: your-org/project-metrics-action@main
        with:
          org: your-organization
          token: ${{ secrets.GITHUB_TOKEN }}
          readme_path: README.md
      - name: Commit changes
        run: |
          git config --local user.email "action@github.com"
          git config --local user.name "GitHub Action"
          git add README.md
          git commit -m "Update project metrics" || exit 0
          git push
```

2. **README Template**: Add these sections to your README.md:

```markdown
<!-- GLOBAL_OVERVIEW:START -->
<!-- GLOBAL_OVERVIEW:END -->

<!-- PROJECT_BREAKDOWN:START -->
<!-- PROJECT_BREAKDOWN:END -->

<!-- LANGUAGES:START -->
<!-- LANGUAGES:END -->

<!-- LAST_UPDATED:START -->
<!-- LAST_UPDATED:END -->
```

### Inputs

- `org` (required): GitHub organization name
- `token` (required): GitHub token with repository access
- `readme_path` (optional): Path to README file (default: `README.md`)

### Outputs

The action generates:

- **Global Overview**: Total tasks by status across all projects
- **Project Breakdown**: Individual project status with completion rates
- **Language Statistics**: Top programming languages by usage
- **Last Updated**: Timestamp of the metrics update

## Project Matching

The action automatically matches repositories to projects using name patterns:

- Projects with "React" → repositories containing "react"
- Projects with "Angular" → repositories containing "angular"
- Projects with "Metrics" → repositories containing "metrics" or "action"
- Projects with "Demo" → repositories containing "demo" or "resume"

## Development

This action is built with:

- **Bash** scripts for data collection and processing
- **AWK** scripts for README template injection
- **GitHub CLI** for API interactions
- **jq** for JSON processing

## License

MIT License - see LICENSE file for details.
