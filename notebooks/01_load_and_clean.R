# 01_load_and_clean.R
# Purpose: Load and clean the diabetes and heart failure datasets

# ---- Package Setup ----
required_packages <- c("tidyverse", "readr", "here")

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg)
  }
  library(pkg, character.only = TRUE)
}

# Load required libraries
library(tidyverse)
library(readr)
library(here)

# Ensure processed folder exists
dir.create(here("data", "processed"), showWarnings = FALSE)

# Load data
diabetes_data <- read_csv(here("data", "raw", "diabetes.csv"))
heart_failure_data <- read_csv(here("data", "raw", "heart_failure.csv"))

# Standardize column names
colnames(diabetes_data) <- make.names(colnames(diabetes_data))

# Clean diabetes data
diabetes_data <- diabetes_data %>%
  mutate(across(where(is.numeric), ~ifelse(is.na(.), median(., na.rm = TRUE), .))) %>%
  mutate(Gender = ifelse(Gender == "Male", 1, 0)) %>%
  mutate(across(all_of(c("Polyuria", "Polydipsia", "sudden.weight.loss", "weakness", 
                         "Polyphagia", "Genital.thrush", "visual.blurring", "Itching", 
                         "Irritability", "delayed.healing", "partial.paresis", 
                         "muscle.stiffness", "Alopecia", "Obesity")),
                ~ ifelse(. == "Yes", 1, 0))) %>%
  mutate(class = as.factor(class)) %>%
  distinct()

# Clean heart failure data
heart_failure_data <- heart_failure_data %>%
  mutate(DEATH_EVENT = as.factor(DEATH_EVENT)) %>%
  distinct()

# Save cleaned data
saveRDS(diabetes_data, here("data", "processed", "cleaned_diabetes.rds"))
saveRDS(heart_failure_data, here("data", "processed", "cleaned_heart_failure.rds"))

cat(" Data successfully loaded, cleaned, and saved to RDS files.\n")

