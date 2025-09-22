#!/usr/bin/env Rscript

# Podcast Analytics: Data Fetch and Analysis Script
# This script fetches podcast data from APIs and performs basic analysis

# Load required libraries
library(tidyverse)
library(httr)
library(jsonlite)
library(lubridate)

# Configuration
cat("Starting podcast analytics pipeline...\n")

# Create output directories if they don't exist
dir.create("data/raw", showWarnings = FALSE, recursive = TRUE)
dir.create("data/processed", showWarnings = FALSE, recursive = TRUE)

# Function to fetch data from API (placeholder implementation)
fetch_podcast_data <- function() {
  cat("Fetching podcast data from API...\n")
  
  # TODO: Replace this with actual API calls
  # Example API call structure:
  # api_key <- Sys.getenv("SPOTIFY_CLIENT_ID")  # Get from environment variables
  # api_secret <- Sys.getenv("SPOTIFY_CLIENT_SECRET")
  # 
  # # Authenticate with API
  # auth_response <- POST(
  #   "https://accounts.spotify.com/api/token",
  #   body = list(
  #     grant_type = "client_credentials",
  #     client_id = api_key,
  #     client_secret = api_secret
  #   ),
  #   encode = "form"
  # )
  # 
  # token <- content(auth_response)$access_token
  # 
  # # Fetch podcast metrics
  # response <- GET(
  #   "https://api.spotify.com/v1/shows/{show_id}/episodes",
  #   add_headers(Authorization = paste("Bearer", token))
  # )
  # 
  # data <- content(response, "text") %>% fromJSON()
  
  # For now, generate sample data for demonstration
  set.seed(42)
  sample_data <- tibble(
    date = seq(from = today() - days(30), to = today(), by = "day"),
    downloads = rpois(31, lambda = 150) + rnorm(31, mean = 0, sd = 20),
    plays = rpois(31, lambda = 120) + rnorm(31, mean = 0, sd = 15),
    unique_listeners = rpois(31, lambda = 100) + rnorm(31, mean = 0, sd = 12),
    episode_title = paste("Episode", 1:31),
    platform = sample(c("Spotify", "Apple Podcasts", "Google Podcasts"), 31, replace = TRUE)
  ) %>%
    mutate(
      downloads = pmax(0, round(downloads)),
      plays = pmax(0, round(plays)),
      unique_listeners = pmax(0, round(unique_listeners))
    )
  
  return(sample_data)
}

# Function to process and analyze data
process_data <- function(raw_data) {
  cat("Processing and analyzing data...\n")
  
  # Basic data cleaning
  processed_data <- raw_data %>%
    # Remove any rows with missing critical data
    filter(!is.na(date), !is.na(downloads)) %>%
    # Ensure proper date format
    mutate(date = as.Date(date)) %>%
    # Sort by date
    arrange(date)
  
  # Calculate 7-day moving averages
  processed_data <- processed_data %>%
    mutate(
      downloads_7day_ma = zoo::rollmean(downloads, k = 7, fill = NA, align = "right"),
      plays_7day_ma = zoo::rollmean(plays, k = 7, fill = NA, align = "right"),
      unique_listeners_7day_ma = zoo::rollmean(unique_listeners, k = 7, fill = NA, align = "right")
    )
  
  # Calculate additional metrics
  processed_data <- processed_data %>%
    mutate(
      play_rate = plays / downloads,
      engagement_rate = unique_listeners / downloads,
      week_day = wday(date, label = TRUE),
      month = month(date, label = TRUE),
      week_of_year = week(date)
    )
  
  # Generate summary statistics
  summary_stats <- processed_data %>%
    summarise(
      total_downloads = sum(downloads, na.rm = TRUE),
      avg_daily_downloads = mean(downloads, na.rm = TRUE),
      median_daily_downloads = median(downloads, na.rm = TRUE),
      total_plays = sum(plays, na.rm = TRUE),
      avg_play_rate = mean(play_rate, na.rm = TRUE),
      avg_engagement_rate = mean(engagement_rate, na.rm = TRUE),
      date_range_start = min(date, na.rm = TRUE),
      date_range_end = max(date, na.rm = TRUE),
      analysis_timestamp = Sys.time()
    )
  
  # Platform-specific analysis
  platform_summary <- processed_data %>%
    group_by(platform) %>%
    summarise(
      total_downloads = sum(downloads, na.rm = TRUE),
      avg_downloads = mean(downloads, na.rm = TRUE),
      total_episodes = n(),
      .groups = "drop"
    ) %>%
    mutate(
      download_share = total_downloads / sum(total_downloads) * 100
    )
  
  return(list(
    processed_data = processed_data,
    summary_stats = summary_stats,
    platform_summary = platform_summary
  ))
}

# Function to save processed data
save_data <- function(data_list) {
  cat("Saving processed data...\n")
  
  # Save processed data as CSV
  write_csv(data_list$processed_data, "data/processed/podcast_metrics_processed.csv")
  write_csv(data_list$summary_stats, "data/processed/summary_statistics.csv")
  write_csv(data_list$platform_summary, "data/processed/platform_summary.csv")
  
  # Save as RDS for R-specific use
  saveRDS(data_list, "data/processed/podcast_analytics.rds")
  
  # Create a simple JSON export for web use
  data_list$processed_data %>%
    select(date, downloads, plays, unique_listeners, downloads_7day_ma) %>%
    toJSON(pretty = TRUE) %>%
    write_file("data/processed/podcast_metrics.json")
  
  cat("Data saved successfully!\n")
}

# Main execution
tryCatch({
  # Step 1: Fetch data
  raw_data <- fetch_podcast_data()
  
  # Save raw data
  write_csv(raw_data, "data/raw/podcast_data_raw.csv")
  
  # Step 2: Process data
  results <- process_data(raw_data)
  
  # Step 3: Save processed data
  save_data(results)
  
  # Print summary
  cat("\n=== ANALYSIS SUMMARY ===\n")
  cat("Date range:", as.character(results$summary_stats$date_range_start), "to", 
      as.character(results$summary_stats$date_range_end), "\n")
  cat("Total downloads:", results$summary_stats$total_downloads, "\n")
  cat("Average daily downloads:", round(results$summary_stats$avg_daily_downloads, 1), "\n")
  cat("Average play rate:", round(results$summary_stats$avg_play_rate * 100, 1), "%\n")
  cat("Average engagement rate:", round(results$summary_stats$avg_engagement_rate * 100, 1), "%\n")
  
  cat("\n=== PLATFORM BREAKDOWN ===\n")
  for(i in 1:nrow(results$platform_summary)) {
    platform <- results$platform_summary$platform[i]
    share <- round(results$platform_summary$download_share[i], 1)
    downloads <- results$platform_summary$total_downloads[i]
    cat(platform, ":", downloads, "downloads (", share, "%)\n")
  }
  
  cat("\nAnalysis completed successfully!\n")
  
}, error = function(e) {
  cat("Error in analysis pipeline:", e$message, "\n")
  quit(status = 1)
})