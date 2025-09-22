# Podcast Analytics Aggregator

This project aggregates and analyzes podcast metrics for the "Bourbon and Rum" podcast (and can be adapted for any podcast), using R. It is designed to pull, process, and visualize data from available podcast analytics sources.

## Features

- Fetch metrics from platforms with accessible APIs (e.g., Spotify/Anchor).
- Aggregate data and generate summary reports.
- Automated workflows using GitHub Actions.

## Structure

```
.
├── .github/workflows/         # GitHub Actions CI/CD workflows
├── data/                      # Data storage (raw and processed)
│   ├── raw/
│   └── processed/
├── scripts/                   # R scripts for data tasks
├── requirements.txt           # R package requirements
├── .gitignore                 # Ignore secrets and temporary files
└── README.md                  # This file
```

## Quick Start

1. Clone the repo.
2. Install R and required packages (see `requirements.txt`).
3. Add your API credentials (if required) as GitHub repository secrets.
4. Adapt scripts in `scripts/` for your podcast platforms.
5. Reports will be generated in the `data/processed/` folder and (optionally) published as artifacts or via GitHub Pages.

## Automation

- **GitHub Actions** (`.github/workflows/r-analytics.yml`) runs R scripts automatically on push or via schedule.

---

## Secret Management

**Never commit API keys, tokens, or credentials to the repo!**

- Store all secrets as [GitHub Actions secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets).
- Reference them in workflows and access via `Sys.getenv()` in R scripts.
- `.gitignore` ensures local secrets/config files are never committed.

## Contributing

PRs welcome. Please open issues for suggestions or bugs.

## License

MIT
