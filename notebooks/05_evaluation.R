# 05_evaluation.R
# Purpose: Pooled out of fold evaluation with model specific Youden thresholds
# Inputs:
#   output/logistic_model.rds
#   output/random_forest_model.rds
# Outputs in output:
#   oof_predictions_logit.csv
#   oof_predictions_rf.csv
#   chosen_thresholds_youden.csv
#   confusion_matrix_logit_oof_youden.csv
#   confusion_matrix_rf_oof_youden.csv
#   performance_metrics_oof_youden.csv
#   logistic_regression_confusion_report_oof_youden.txt
#   random_forest_confusion_report_oof_youden.txt
#   roc_logit_oof.png
#   roc_rf_oof.png

suppressPackageStartupMessages({
  library(here)
  library(caret)
  library(pROC)
  library(dplyr)
})

set.seed(20251230)

# ----------------------------
# Paths
# ----------------------------
out_dir <- here::here("output")
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

logit_model_path <- file.path(out_dir, "logistic_model.rds")
rf_model_path    <- file.path(out_dir, "random_forest_model.rds")

if (!file.exists(logit_model_path)) stop("Missing model file: ", logit_model_path, "\nRun 04_model_training.R first.")
if (!file.exists(rf_model_path))    stop("Missing model file: ", rf_model_path, "\nRun 04_model_training.R first.")

logit_model <- readRDS(logit_model_path)
rf_model    <- readRDS(rf_model_path)

# ----------------------------
# Extract pooled out of fold predictions
# ----------------------------
logit_pred <- logit_model$pred
rf_pred    <- rf_model$pred

if (is.null(logit_pred) || nrow(logit_pred) == 0) {
  stop("logit_model$pred is empty. Confirm savePredictions equals final in trainControl.")
}
if (is.null(rf_pred) || nrow(rf_pred) == 0) {
  stop("rf_model$pred is empty. Confirm savePredictions equals final in trainControl.")
}

# Determine observed levels from the training data outcome
# This prevents silent level inversion across scripts
get_obs_levels <- function(train_obj) {
  td <- train_obj$trainingData
  if (!(".outcome" %in% names(td))) stop("trainingData does not contain .outcome")
  levels(td$.outcome)
}

obs_levels_logit <- get_obs_levels(logit_model)
obs_levels_rf    <- get_obs_levels(rf_model)

if (!identical(obs_levels_logit, obs_levels_rf)) {
  stop(
    "Outcome level ordering differs between models.\n",
    "Logit levels: ", paste(obs_levels_logit, collapse = ", "), "\n",
    "RF levels: ", paste(obs_levels_rf, collapse = ", "), "\n",
    "Ensure both models used identical folds and identical outcome encoding in 04_model_training.R."
  )
}

# We expect Yes then No from 04_model_training.R
# But we will compute using whatever ordering is actually present, then enforce explicit positive label
positive_class <- "Yes"
negative_class <- setdiff(obs_levels_logit, positive_class)[1]

if (is.na(negative_class)) stop("Could not infer negative class. Outcome levels: ", paste(obs_levels_logit, collapse = ", "))

# Normalize obs factor levels in prediction frames
logit_pred$obs <- factor(logit_pred$obs, levels = c(negative_class, positive_class))
rf_pred$obs    <- factor(rf_pred$obs, levels = c(negative_class, positive_class))

# Probability column checks
if (!(positive_class %in% names(logit_pred))) stop("logit_pred missing probability column named ", positive_class)
if (!(positive_class %in% names(rf_pred)))    stop("rf_pred missing probability column named ", positive_class)

# Save pooled out of fold predictions for auditability
write.csv(logit_pred, file.path(out_dir, "oof_predictions_logit.csv"), row.names = FALSE)
write.csv(rf_pred,    file.path(out_dir, "oof_predictions_rf.csv"),    row.names = FALSE)

# ----------------------------
# ROC and AUC from pooled out of fold probabilities
# ----------------------------
roc_logit <- roc(
  response  = logit_pred$obs,
  predictor = logit_pred[[positive_class]],
  levels    = c(negative_class, positive_class),
  direction = "<",
  quiet     = TRUE
)

roc_rf <- roc(
  response  = rf_pred$obs,
  predictor = rf_pred[[positive_class]],
  levels    = c(negative_class, positive_class),
  direction = "<",
  quiet     = TRUE
)

auc_logit <- as.numeric(auc(roc_logit))
auc_rf    <- as.numeric(auc(roc_rf))

# ----------------------------
# Model specific Youden thresholds from pooled out of fold predictions
# ----------------------------
threshold_logit <- coords(
  roc_logit,
  x = "best",
  best.method = "youden",
  ret = "threshold"
)
threshold_logit <- as.numeric(unname(threshold_logit[1]))

threshold_rf <- coords(
  roc_rf,
  x = "best",
  best.method = "youden",
  ret = "threshold"
)
threshold_rf <- as.numeric(unname(threshold_rf[1]))

write.csv(
  data.frame(
    model = c("logistic_regression", "random_forest"),
    threshold = c(threshold_logit, threshold_rf)
  ),
  file.path(out_dir, "chosen_thresholds_youden.csv"),
  row.names = FALSE
)

# ----------------------------
# Confusion matrices from pooled out of fold predictions
# ----------------------------
make_cm <- function(pred_df, threshold, positive_label, negative_label) {
  pred_class <- ifelse(pred_df[[positive_label]] >= threshold, positive_label, negative_label)
  pred_class <- factor(pred_class, levels = c(negative_label, positive_label))
  obs_class  <- factor(pred_df$obs, levels = c(negative_label, positive_label))
  caret::confusionMatrix(pred_class, obs_class, positive = positive_label)
}

cm_logit <- make_cm(logit_pred, threshold_logit, positive_class, negative_class)
cm_rf    <- make_cm(rf_pred, threshold_rf, positive_class, negative_class)

# Save confusion matrix tables
write.csv(
  as.data.frame(cm_logit$table),
  file.path(out_dir, "confusion_matrix_logit_oof_youden.csv"),
  row.names = FALSE
)
write.csv(
  as.data.frame(cm_rf$table),
  file.path(out_dir, "confusion_matrix_rf_oof_youden.csv"),
  row.names = FALSE
)

# Save full caret style printed reports
sink(file.path(out_dir, "logistic_regression_confusion_report_oof_youden.txt"))
print(cm_logit)
sink()

sink(file.path(out_dir, "random_forest_confusion_report_oof_youden.txt"))
print(cm_rf)
sink()

# ----------------------------
# Performance metrics table
# ----------------------------
extract_byclass <- function(cm_obj) {
  bc <- cm_obj$byClass
  data.frame(
    sensitivity = as.numeric(bc["Sensitivity"]),
    specificity = as.numeric(bc["Specificity"]),
    precision   = as.numeric(bc["Precision"]),
    recall      = as.numeric(bc["Recall"]),
    f1          = as.numeric(bc["F1"])
  )
}

metrics_logit <- extract_byclass(cm_logit)
metrics_rf    <- extract_byclass(cm_rf)

metrics_tbl <- bind_rows(
  data.frame(
    model = "logistic_regression",
    auc = auc_logit,
    threshold = threshold_logit
  ) %>% bind_cols(metrics_logit),
  data.frame(
    model = "random_forest",
    auc = auc_rf,
    threshold = threshold_rf
  ) %>% bind_cols(metrics_rf)
)

write.csv(
  metrics_tbl,
  file.path(out_dir, "performance_metrics_oof_youden.csv"),
  row.names = FALSE
)

# ----------------------------
# ROC plots
# ----------------------------
save_roc_plot <- function(roc_obj, title_text, filename) {
  png(file.path(out_dir, filename), width = 1400, height = 1000, res = 150)
  plot(roc_obj, main = title_text)
  abline(a = 0, b = 1)
  dev.off()
}

save_roc_plot(roc_logit, "ROC Logistic Regression Pooled Out of Fold", "roc_logit_oof.png")
save_roc_plot(roc_rf,    "ROC Random Forest Pooled Out of Fold",       "roc_rf_oof.png")

# ----------------------------
# Console summary
# ----------------------------
cat("Evaluation complete using pooled out of fold predictions.\n")
cat("AUC logistic regression: ", round(auc_logit, 3), "\n")
cat("AUC random forest: ", round(auc_rf, 3), "\n")
cat("Youden threshold logistic regression: ", signif(threshold_logit, 4), "\n")
cat("Youden threshold random forest: ", signif(threshold_rf, 4), "\n")
cat("Outputs saved to: ", out_dir, "\n")

