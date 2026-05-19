# CVD Risk Prediction in Diabetic Patients Using Machine Learning

[![Published](https://img.shields.io/badge/Published-Artificial_Intelligence_in_Health-darkgreen?style=flat-square)](https://doi.org/10.36922/AIH025490111)
[![DOI](https://img.shields.io/badge/DOI-10.36922%2FAIH025490111-blue?style=flat-square)](https://doi.org/10.36922/AIH025490111)
[![SSRN](https://img.shields.io/badge/SSRN-5091734-2c3e50?style=flat-square)](https://doi.org/10.2139/ssrn.5091734)
[![ORCID](https://img.shields.io/badge/ORCID-0009--0001--9929--3135-a6ce39?style=flat-square&logo=orcid&logoColor=white)](https://orcid.org/0009-0001-9929-3135)
![R](https://img.shields.io/badge/R-4.3.2-blue?style=flat-square)
![Reproducible](https://img.shields.io/badge/Reproducible-Yes-success?style=flat-square)
![Validation](https://img.shields.io/badge/Validation-Five_Fold_CV-important?style=flat-square)
![Evaluation](https://img.shields.io/badge/Evaluation-Pooled_Out_of_Fold-blueviolet?style=flat-square)
![License](https://img.shields.io/badge/License-CC0_1.0-lightgrey?style=flat-square)

[![Reproducible R Pipeline](https://github.com/julian-borges-md/cvd-diabetes-risk-ml/actions/workflows/r1.yml/badge.svg)](https://github.com/julian-borges-md/cvd-diabetes-risk-ml/actions/workflows/r1.yml)

> **Published in Artificial Intelligence in Health (AccScience Publishing, 2026)**
> Open Access | DOI: [10.36922/AIH025490111](https://doi.org/10.36922/AIH025490111)

---

## Why this project exists

Cardiovascular disease remains a leading cause of morbidity and mortality among patients with diabetes and heart failure. Although machine learning has been widely proposed for clinical risk stratification, many published studies rely on flawed evaluation practices, including:

- Single train test splits  
- In sample or partially leaked evaluation  
- Post hoc refitting on full datasets  
- Unclear or improper handling of class imbalance  

These practices inflate reported performance and undermine clinical trust.

This project asks a simpler but more important question:

**When evaluated correctly, how well do standard and interpretable models perform on real clinical data**

---

## Clinical question

Can early stage diabetes symptoms and standard clinical biomarkers predict cardiovascular mortality in patients with heart failure

This pipeline evaluates that question using:

- Symptom based features from early stage diabetes  
- Laboratory and demographic features from heart failure cohorts  
- Interpretable baseline and ensemble models  

---

## Objective

To evaluate the predictive value of early stage diabetes symptoms and selected clinical biomarkers including serum creatinine, ejection fraction, and age for estimating heart failure related mortality risk, using interpretable and fully reproducible machine learning methods under leakage resistant validation.

---

## Methods

### Programming language
R

### Modeling approach

#### Models
- Logistic regression as an interpretable baseline  
- Random forest as a nonlinear ensemble  

#### Validation strategy
- Five fold cross validation  
- Identical folds shared across models  
- Class imbalance handled via up sampling within training folds only  
- No test set leakage  
- No post hoc refitting  

#### Metrics reported
- Area under the receiver operating characteristic curve AUC  
- Sensitivity  
- Specificity  

All performance metrics are computed exclusively from **pooled out of fold predictions**.

Threshold dependent metrics are computed using model specific probability thresholds selected by maximizing Youden’s J statistic from pooled out of fold predicted probabilities.

### Key R packages
- caret  
- randomForest  
- pROC  
- dplyr  
- ggplot2  
- here  
- renv  

---

## Datasets used

This project uses publicly available datasets from the UCI Machine Learning Repository.

### Early Stage Diabetes Risk Prediction Dataset  
https://archive.ics.uci.edu/ml/datasets/Early+stage+diabetes+risk+prediction+dataset

### Heart Failure Clinical Records Dataset  
https://archive.ics.uci.edu/ml/datasets/Heart+failure+clinical+records

Raw CSV files must be placed in:

data/raw/
├── diabetes.csv
└── heart_failure.csv

The diabetes dataset is used exclusively for exploratory analysis and feature engineering demonstration and does not contribute to outcome modeling.

---

## Repository structure

```
cvd-diabetes-risk-ml/
│
├── data/
│ ├── raw/
│ │ ├── diabetes.csv
│ │ └── heart_failure.csv
│ └── processed/
│ ├── cleaned_diabetes.rds
│ ├── cleaned_heart_failure.rds
│ ├── processed_diabetes.rds
│ └── processed_heart_failure.rds
│
├── models/
│ ├── logistic_model.rds
│ └── random_forest_model.rds
│
├── notebooks/
│ ├── 01_load_and_clean.R
│ ├── 02_exploration.R
│ ├── 03_feature_engineering.R
│ ├── 04_model_training.R
│ └── 05_evaluation.R
│ └── 06_results_and_visuals.R
│ └── 07_render_caret_reports.R
│ └── 08_figures_7_8.R
│ └── 09_tables_confusion_matrices.R
│
├── output/
│ ├── figures
│ ├── tables
│ ├── cv_metrics.csv
│ ├── roc_oof.png
│ └── sessionInfo.txt
│
├── renv/
├── renv.lock
├── README.md
├── .gitignore
└── LICENSE
```

---

## Pipeline overview

| Step | Script | Description |
|----:|--------|-------------|
| 1 | notebooks/01_load_and_clean.R | Load raw datasets, clean variables, standardize naming |
| 2 | notebooks/02_exploration.R | Exploratory analysis and cohort characterization |
| 3 | notebooks/03_feature_engineering.R | Feature creation and normalization |
| 4 | notebooks/04_model_training.R | Model training using five fold cross validation |
| 5 | notebooks/05_evaluation.R | Pooled out of fold evaluation, Youden thresholds, ROC curves |

Optional manuscript tables:

| Step | Script | Description |
|----:|--------|-------------|
| 6 | notebooks/09_tables_confusion_matrices.R | Journal style confusion matrix tables derived from pooled out of fold predictions |

---

## Reproducibility guarantees

- All package versions are locked using renv  
- All file paths are project relative using here  
- Cross validation precedes any evaluation  
- Performance metrics are computed only from pooled out of fold predictions  
- Class imbalance handling is confined to training folds  
- No test data leakage or post hoc refitting is performed  

---

## Run the entire analysis in one command

From the project root:

Rscript -e 'renv::restore(); \
source("notebooks/01_load_and_clean.R"); \
source("notebooks/02_exploration.R"); \
source("notebooks/03_feature_engineering.R"); \
source("notebooks/04_model_training.R"); \
source("notebooks/05_evaluation.R"); \
source("notebooks/09_tables_confusion_matrices.R")'

# Disclosure and Reproducibility Statement
This study was conducted solely by the author and received no external funding or financial support. The author declares no competing interests. All analyses were performed using publicly available, fully de identified datasets and did not involve human participants, clinical interventions, or identifiable personal data. Accordingly, institutional review board approval and informed consent were not required.
Model development and evaluation were implemented through a fully scripted and version controlled analytic pipeline designed to ensure transparency, auditability, and reproducibility. All performance estimates were derived exclusively from pooled out of fold predictions generated under five fold cross validation, thereby avoiding in sample or single split inflation. Class imbalance handling and preprocessing steps were confined strictly to training folds to prevent information leakage.
Interpretable baseline models were intentionally prioritized, and validation practices were aligned with principles articulated in FDA Good Machine Learning Practice guidance, emphasizing conservative evaluation, clear operating characteristics, and clinically inspectable behavior.
All code, analytic procedures, and intermediate outputs are publicly available to support independent replication. The author welcomes correspondence regarding methodological details, reproducibility, and potential extensions of this work.

# Corresponding Author
Julian Borges, MD, MSc Physician Scientist MS in Health Informatics Candidate Boston University Boston, MA, United States
Email: jyborges@bu.edu

---

<div align="center">

**Frontier Translational Research Lab**

Department of Computer Science · Boston University · Harvard Medical School GCSRT Alumni

[![Lab Website](https://img.shields.io/badge/Lab-frontier--lab-002244?style=flat-square)](https://julian-borges-md.github.io/frontier-lab/)
[![BU CS](https://img.shields.io/badge/BU-Computer_Science-cc0000?style=flat-square)](https://www.bu.edu/cs/)
[![HMS](https://img.shields.io/badge/HMS-GCSRT_Alumni-a51c30?style=flat-square)](https://ghsm.hms.harvard.edu/education/global-clinical-scholars-research-training)
[![ORCID](https://img.shields.io/badge/ORCID-0009--0001--9929--3135-a6ce39?style=flat-square&logo=orcid&logoColor=white)](https://orcid.org/0009-0001-9929-3135)
[![CV](https://img.shields.io/badge/Academic_CV-research--profile-4f46e5?style=flat-square)](https://julian-borges-md.github.io/research-profile/)

*Julian Borges, MD, MS · jyborges@bu.edu*

</div>
