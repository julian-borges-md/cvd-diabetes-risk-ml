# 02_exploration.R
# Purpose: Exploratory analysis

suppressPackageStartupMessages({
  library(tidyverse)
  library(corrplot)
  library(here)
})

# ----------------------------
# Resolve output directory
# ----------------------------
out_dir <- here::here("output")
if (!dir.exists(out_dir)) {
  dir.create(out_dir, recursive = TRUE)
}
cat("Writing figures to:", out_dir, "\n")

# ----------------------------
# Load cleaned datasets
# ----------------------------
diabetes_path <- here::here("data", "processed", "cleaned_diabetes.rds")
hf_path       <- here::here("data", "processed", "cleaned_heart_failure.rds")

stopifnot(file.exists(diabetes_path))
stopifnot(file.exists(hf_path))

diabetes_data       <- readRDS(diabetes_path)
heart_failure_data <- readRDS(hf_path)

# ----------------------------
# Figure 1: Correlation matrix – Diabetes
# ----------------------------
numeric_diabetes <- diabetes_data %>% select(where(is.numeric))

png(
  filename = file.path(out_dir, "Figure_1_Correlation_Matrix_Diabetes.png"),
  width = 1600,
  height = 1600,
  res = 200
)
corrplot(
  cor(numeric_diabetes, use = "complete.obs"),
  method = "circle",
  title = "Figure 1. Correlation matrix Diabetes dataset",
  mar = c(0, 0, 3, 0)
)
dev.off()

# ----------------------------
# Figure 2: Correlation matrix – Heart failure
# ----------------------------
numeric_hf <- heart_failure_data %>% select(where(is.numeric))

png(
  filename = file.path(out_dir, "Figure_2_Correlation_Matrix_Heart_Failure.png"),
  width = 1600,
  height = 1600,
  res = 200
)
corrplot(
  cor(numeric_hf, use = "complete.obs"),
  method = "circle",
  title = "Figure 2. Correlation matrix Heart failure dataset",
  mar = c(0, 0, 3, 0)
)
dev.off()

# ----------------------------
# Figure 3: Age distribution – Diabetes
# ----------------------------
p3 <- ggplot(diabetes_data, aes(x = Age)) +
  geom_histogram(binwidth = 5, fill = "steelblue", color = "black") +
  labs(
    title = "Figure 3. Age distribution Diabetes dataset",
    x = "Age (years)",
    y = "Count"
  ) +
  theme_minimal(base_size = 14)

ggsave(
  filename = file.path(out_dir, "Figure_3_Age_Distribution_Diabetes.png"),
  plot = p3,
  width = 7,
  height = 5,
  dpi = 300
)

# ----------------------------
# Figure 4: Age distribution – Heart failure
# ----------------------------
p4 <- ggplot(heart_failure_data, aes(x = age)) +
  geom_histogram(binwidth = 5, fill = "salmon", color = "black") +
  labs(
    title = "Figure 4. Age distribution Heart failure dataset",
    x = "Age (years)",
    y = "Count"
  ) +
  theme_minimal(base_size = 14)

ggsave(
  filename = file.path(out_dir, "Figure_4_Age_Distribution_Heart_Failure.png"),
  plot = p4,
  width = 7,
  height = 5,
  dpi = 300
)

cat("Exploratory analysis complete. Figures 1–4 generated.\n")

