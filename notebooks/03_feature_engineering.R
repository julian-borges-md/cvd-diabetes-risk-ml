# 03_feature_engineering.R
# Purpose: Create engineered features and normalize datasets

suppressPackageStartupMessages({
  library(dplyr)
  library(here)
  library(stringr)
})

diabetes_in <- here("data", "processed", "cleaned_diabetes.rds")
hf_in <- here("data", "processed", "cleaned_heart_failure.rds")

diabetes_out <- here("data", "processed", "processed_diabetes.rds")
hf_out <- here("data", "processed", "processed_heart_failure.rds")

if (!file.exists(diabetes_in)) stop("Missing input file: ", diabetes_in)
if (!file.exists(hf_in)) stop("Missing input file: ", hf_in)

diabetes_data <- readRDS(diabetes_in)
heart_failure_data <- readRDS(hf_in)

# Standardize column names to snake case for matching
standardize_names <- function(nms) {
  nms |>
    str_trim() |>
    str_to_lower() |>
    str_replace_all("[^a-z0-9]+", "_") |>
    str_replace_all("^_|_$", "")
}

names(diabetes_data) <- standardize_names(names(diabetes_data))
names(heart_failure_data) <- standardize_names(names(heart_failure_data))

# Helper: safe numeric scaling returning numeric vector
scale_num <- function(x) as.numeric(scale(x))

# Map required symptom columns, allowing common variants
# After standardization, "sudden.weight.loss" becomes "sudden_weight_loss"
required <- c("polyuria", "polydipsia", "sudden_weight_loss", "weakness", "polyphagia")
missing <- setdiff(required, names(diabetes_data))

if (length(missing) > 0) {
  stop(
    "Cannot compute symptom_severity. Missing columns after standardization: ",
    paste(missing, collapse = ", "),
    "\nAvailable columns include: ",
    paste(head(names(diabetes_data), 30), collapse = ", ")
  )
}

diabetes_data <- diabetes_data %>%
  mutate(
    symptom_severity =
      .data$polyuria +
      .data$polydipsia +
      .data$sudden_weight_loss +
      .data$weakness +
      .data$polyphagia
  )

# Scale numeric predictors only (never scale outcomes)
diab_outcomes <- intersect(names(diabetes_data), c("class", "outcome", "label"))
diab_num_cols <- names(diabetes_data)[sapply(diabetes_data, is.numeric)]
diab_scale_cols <- setdiff(diab_num_cols, diab_outcomes)

diabetes_data_scaled <- diabetes_data %>%
  mutate(across(all_of(diab_scale_cols), ~ scale_num(.x)))

hf_outcomes <- intersect(names(heart_failure_data), c("death_event", "outcome", "label"))
hf_num_cols <- names(heart_failure_data)[sapply(heart_failure_data, is.numeric)]
hf_scale_cols <- setdiff(hf_num_cols, hf_outcomes)

heart_failure_data_scaled <- heart_failure_data %>%
  mutate(across(all_of(hf_scale_cols), ~ scale_num(.x)))

# Save only if everything succeeded
saveRDS(diabetes_data_scaled, diabetes_out)
saveRDS(heart_failure_data_scaled, hf_out)

cat("Feature engineering and scaling complete.\n")
cat("Saved:\n")
cat("  ", diabetes_out, "\n")
cat("  ", hf_out, "\n")
