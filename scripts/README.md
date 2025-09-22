# Scripts Directory

This directory contains R scripts for podcast analytics processing.

## Current Scripts

### `fetch_rss.R`
- **Purpose**: Fetches and processes episode-level metadata from the podcast RSS feed
- **Input**: RSS feed URL (configured in script)
- **Output**: `data/processed/episodes_metadata.csv`
- **Schedule**: Runs daily via GitHub Actions to keep episode database current
- **Dependencies**: tidyRSS, dplyr, readr, lubridate, stringr

#### Key Features:
- Robust error handling with backup capability
- Automatic data cleaning and standardization
- Date parsing and time-based analytics preparation
- Summary statistics output
- Configurable RSS URL for different podcasts

#### Data Fields Extracted:
- Episode title and description
- Publish date and time
- Episode link and GUID
- Duration (if available)
- Episode/season numbers
- Computed fields: description length, day of week, month, year

## Future Extension

### Adding New Scripts
1. Create new `.R` files in this directory
2. Follow the established pattern:
   - Load required libraries with `suppressMessages()`
   - Use proper error handling with `tryCatch()`
   - Include configuration section at top
   - Add comprehensive comments
   - Output processed data to `data/processed/`

### Integration with GitHub Actions
- The workflow automatically runs all `.R` scripts found in this directory
- Scripts run in alphabetical order after `fetch_rss.R`
- Add new dependencies to `requirements.txt`
- Use environment variables for API keys and secrets

### Recommended Next Scripts
- `analyze_trends.R`: Time-series analysis of episode metrics
- `generate_reports.R`: Create visualizations and summary reports
- `api_integrations.R`: Fetch data from podcast platform APIs
- `social_metrics.R`: Analyze social media engagement

### Best Practices
- Always validate input data before processing
- Use consistent file naming: `verb_noun.R`
- Include logging output for debugging
- Handle missing or malformed data gracefully
- Document configuration options at the top of each script