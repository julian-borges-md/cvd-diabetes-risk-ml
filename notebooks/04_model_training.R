# 04_model_training.R
# Purpose: Train logistic regression and random forest models using five fold cross validation
# Outputs:
#   output/logistic_model.rds
#   output/random_forest_model.rds

suppressPackageStartupMessages({
  library(dplyr)
  library(caret)
  library(randomForest)
  library(here)
})

set.seed(20251230)

# Inputs from feature engineering step
hf_path <- here::here("data", "processed", "processed_heart_failure.rds")
if (!file.exists(hf_path)) {
  stop("Missing input file: ", hf_path, "\nRun 03_feature_engineering.R first.")
}

heart_failure_data <- readRDS(hf_path)

# Detect outcome column robustly
nms <- names(heart_failure_data)
outcome_col <- c("death_event", "DEATH_EVENT")[c("death_event", "DEATH_EVENT") %in% nms][1]
if (is.na(outcome_col)) {
  stop("No outcome column found. Expected death_event or DEATH_EVENT. Found: ", paste(nms, collapse = ", "))
}

# Standardize outcome to factor with levels Yes then No
y <- heart_failure_data[[outcome_col]]

if (is.numeric(y) || is.integer(y)) {
  y <- ifelse(y == 1, "Yes", "No")
} else {
  y <- as.character(y)
  y <- ifelse(y %in% c("1", "yes", "Yes", "TRUE", "true"), "Yes", "No")
}

heart_failure_data[[outcome_col]] <- factor(y, levels = c("Yes", "No"))

# Define predictors explicitly
predictor_cols <- setdiff(names(heart_failure_data), outcome_col)

# Create identical stratified folds once and reuse across models
fold_index <- caret::createFolds(heart_failure_data[[outcome_col]], k = 5, returnTrain = TRUE)

# Five fold CV control with within fold up sampling
cv_control <- trainControl(
  method = "cv",
  number = 5,
  index = fold_index,
  classProbs = TRUE,
  summaryFunction = twoClassSummary,
  savePredictions = "final",
  sampling = "up"
)

# Ensure output folder exists
out_dir <- here::here("output")
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

# Model formula
model_formula <- reformulate(termlabels = predictor_cols, response = outcome_col)

# Logistic regression
logit_model <- train(
  model_formula,
  data = heart_failure_data,
  method = "glm",
  family = "binomial",
  trControl = cv_control,
  metric = "ROC"
)

# Random forest
rf_model <- train(
  model_formula,
  data = heart_failure_data,
  method = "rf",
  trControl = cv_control,
  metric = "ROC",
  ntree = 500
)

# Print results
cat("\nLogistic regression five fold cross validation\n")
print(logit_model)

cat("\nRandom forest five fold cross validation\n")
print(rf_model)

# Save models where evaluation and figures expect them
saveRDS(logit_model, file.path(out_dir, "logistic_model.rds"))
saveRDS(rf_model, file.path(out_dir, "random_forest_model.rds"))

cat("\nModel training complete.\n")
cat("Saved models to: ", out_dir, "\n")

# Sanity checks for auditability
cat("\nOutcome levels:\n")
print(levels(heart_failure_data[[outcome_col]]))

cat("\nOut of fold predictions preview logistic regression:\n")
print(head(logit_model$pred))

cat("\nOut of fold predictions preview random forest:\n")
print(head(rf_model$pred))

cat("\nPrediction columns logistic regression:\n")
print(colnames(logit_model$pred))

cat("\nPrediction columns random forest:\n")
print(colnames(rf_model$pred))

