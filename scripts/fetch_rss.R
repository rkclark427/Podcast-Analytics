#!/usr/bin/env Rscript

# fetch_rss.R
# Purpose: Fetch and process episode-level metadata from podcast RSS feed
# Author: Podcast Analytics Aggregator
# Date: 2024

# Load required libraries
suppressMessages({
  library(tidyRSS)
  library(dplyr)
  library(readr)
  library(lubridate)
  library(stringr)
})

# Configuration
RSS_URL <- "https://anchor.fm/s/f94a9cd8/podcast/rss"
OUTPUT_DIR <- "data/processed"
OUTPUT_FILE <- file.path(OUTPUT_DIR, "episodes_metadata.csv")

# Ensure output directory exists
if (!dir.exists(OUTPUT_DIR)) {
  dir.create(OUTPUT_DIR, recursive = TRUE)
  cat("Created output directory:", OUTPUT_DIR, "\n")
}

# Function to safely fetch RSS feed with error handling
fetch_rss_safely <- function(url) {
  tryCatch({
    cat("Fetching RSS feed from:", url, "\n")
    rss_data <- tidyfeed(url)
    cat("Successfully fetched", nrow(rss_data), "episodes\n")
    return(rss_data)
  }, error = function(e) {
    cat("Error fetching RSS feed:", e$message, "\n")
    return(NULL)
  })
}

# Function to process and clean episode metadata
process_episode_data <- function(rss_data) {
  if (is.null(rss_data) || nrow(rss_data) == 0) {
    cat("No data to process\n")
    return(NULL)
  }
  
  # Process and clean the data
  processed_data <- rss_data %>%
    # Select and rename key columns (adjust based on actual RSS structure)
    select(
      episode_title = item_title,
      episode_description = item_description,
      publish_date = item_pub_date,
      episode_link = item_link,
      episode_guid = item_guid,
      # Additional fields that may be present
      duration = contains("duration"),
      episode_number = contains("episode"),
      season_number = contains("season")
    ) %>%
    # Clean and standardize data
    mutate(
      # Parse and standardize publish date
      publish_date = ymd_hms(publish_date, quiet = TRUE),
      publish_date_formatted = format(publish_date, "%Y-%m-%d %H:%M:%S"),
      
      # Extract episode number from title if not already present
      episode_number_extracted = str_extract(episode_title, "\\b\\d+\\b"),
      
      # Clean description text (remove HTML tags if present)
      episode_description_clean = str_remove_all(episode_description, "<[^>]*>"),
      episode_description_clean = str_squish(episode_description_clean),
      
      # Calculate description length for analytics
      description_length = nchar(episode_description_clean),
      
      # Extract day of week and month for time-based analysis
      publish_day_of_week = weekdays(publish_date),
      publish_month = month(publish_date, label = TRUE),
      publish_year = year(publish_date),
      
      # Data fetch timestamp
      data_fetched_at = Sys.time()
    ) %>%
    # Sort by publish date (newest first)
    arrange(desc(publish_date))
  
  cat("Processed", nrow(processed_data), "episodes with metadata\n")
  return(processed_data)
}

# Function to save data with backup capability
save_episode_data <- function(data, output_file) {
  if (is.null(data)) {
    cat("No data to save\n")
    return(FALSE)
  }
  
  tryCatch({
    # Create backup of existing file if it exists
    if (file.exists(output_file)) {
      backup_file <- paste0(output_file, ".backup.", format(Sys.time(), "%Y%m%d_%H%M%S"))
      file.copy(output_file, backup_file)
      cat("Created backup:", backup_file, "\n")
    }
    
    # Save the new data
    write_csv(data, output_file)
    cat("Successfully saved episode data to:", output_file, "\n")
    cat("Total episodes saved:", nrow(data), "\n")
    
    # Print summary statistics
    cat("\n=== EPISODE DATA SUMMARY ===\n")
    cat("Date range:", as.character(min(data$publish_date, na.rm = TRUE)), 
        "to", as.character(max(data$publish_date, na.rm = TRUE)), "\n")
    cat("Average description length:", round(mean(data$description_length, na.rm = TRUE)), "characters\n")
    cat("Episodes by year:\n")
    print(table(data$publish_year, useNA = "ifany"))
    
    return(TRUE)
  }, error = function(e) {
    cat("Error saving data:", e$message, "\n")
    return(FALSE)
  })
}

# Main execution
main <- function() {
  cat("Starting RSS feed processing...\n")
  cat("Timestamp:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n\n")
  
  # Fetch RSS data
  rss_data <- fetch_rss_safely(RSS_URL)
  
  # Process the data
  processed_data <- process_episode_data(rss_data)
  
  # Save the processed data
  success <- save_episode_data(processed_data, OUTPUT_FILE)
  
  if (success) {
    cat("\n✓ RSS processing completed successfully!\n")
    cat("Episode database updated:", OUTPUT_FILE, "\n")
  } else {
    cat("\n✗ RSS processing failed!\n")
    quit(status = 1)
  }
}

# Execute main function if script is run directly
if (!interactive()) {
  main()
}