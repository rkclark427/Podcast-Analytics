#!/usr/bin/env Rscript

# analyze_episodes.R
# Purpose: Main analytics script for episode data analysis
# Author: Podcast Analytics Aggregator
# Date: 2024
#
# This script performs basic analysis on the episode metadata
# fetched by fetch_rss.R and generates summary insights.

# Load required libraries
suppressMessages({
  library(dplyr)
  library(readr)
  library(ggplot2)
  library(lubridate)
})

# Configuration
INPUT_FILE <- "data/processed/episodes_metadata.csv"
OUTPUT_DIR <- "data/processed"

# Function to load and validate episode data
load_episode_data <- function(file_path) {
  if (!file.exists(file_path)) {
    cat("Episode data file not found:", file_path, "\n")
    cat("Please run fetch_rss.R first to generate episode data.\n")
    return(NULL)
  }
  
  tryCatch({
    data <- read_csv(file_path, show_col_types = FALSE)
    cat("Loaded", nrow(data), "episodes for analysis\n")
    return(data)
  }, error = function(e) {
    cat("Error loading episode data:", e$message, "\n")
    return(NULL)
  })
}

# Function to generate basic analytics
generate_basic_analytics <- function(episodes_data) {
  if (is.null(episodes_data) || nrow(episodes_data) == 0) {
    cat("No data available for analysis\n")
    return(NULL)
  }
  
  # Basic statistics
  analytics <- list(
    total_episodes = nrow(episodes_data),
    date_range = list(
      earliest = min(episodes_data$publish_date, na.rm = TRUE),
      latest = max(episodes_data$publish_date, na.rm = TRUE)
    ),
    avg_description_length = mean(episodes_data$description_length, na.rm = TRUE),
    episodes_by_year = table(episodes_data$publish_year, useNA = "ifany"),
    episodes_by_day_of_week = table(episodes_data$publish_day_of_week, useNA = "ifany"),
    episodes_by_month = table(episodes_data$publish_month, useNA = "ifany")
  )
  
  return(analytics)
}

# Function to display analytics results
display_analytics <- function(analytics) {
  if (is.null(analytics)) return()
  
  cat("\n=== PODCAST EPISODE ANALYTICS ===\n")
  cat("Total Episodes:", analytics$total_episodes, "\n")
  cat("Date Range:", as.character(analytics$date_range$earliest), 
      "to", as.character(analytics$date_range$latest), "\n")
  cat("Average Description Length:", round(analytics$avg_description_length), "characters\n\n")
  
  cat("Episodes by Year:\n")
  print(analytics$episodes_by_year)
  
  cat("\nEpisodes by Day of Week:\n")
  print(analytics$episodes_by_day_of_week)
  
  cat("\nEpisodes by Month:\n")
  print(analytics$episodes_by_month)
}

# Main execution
main <- function() {
  cat("Starting episode analytics...\n")
  cat("Timestamp:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
  
  # Load episode data
  episodes_data <- load_episode_data(INPUT_FILE)
  
  if (is.null(episodes_data)) {
    cat("Cannot proceed without episode data\n")
    quit(status = 1)
  }
  
  # Generate analytics
  analytics <- generate_basic_analytics(episodes_data)
  
  # Display results
  display_analytics(analytics)
  
  cat("\n✓ Episode analytics completed successfully!\n")
  cat("Note: This is a basic analytics script.\n")
  cat("Add more sophisticated analysis functions as needed.\n")
}

# Execute main function if script is run directly
if (!interactive()) {
  main()
}