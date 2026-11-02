# Replication and Extension of Bi and Zubairy (2023)

**Course:** BEEM136 — Research Methods I  
**Researcher:** June  
**Paper:** Bi and Zubairy (2023), *Public Pension Reforms and Retirement Decisions: Narrative Evidence and Aggregate Implications*

## 1. Overview

This project replicates Figure 7 of Bi and Zubairy (2023), which examines the effects of immediate and delayed public pension reforms on labour force participation and pension spending.

I also conduct a sample-period sensitivity analysis by changing the starting year of the sample.

The original replication package is preserved in `Draft_Tables_Figs/`. My replication scripts are stored in `my_code/`, and the outputs are organised in `output/`.

## 2. Software

The replication was carried out using:

- Stata 19.5
- R 4.6.1
- R packages: `readxl`, `tidyverse`

The complete original replication package also uses MATLAB and Excel.

## 3. Replication Workflow

### Step 01 — Replication using the authors' dataset

**Script:** `my_code/replicate_figure7.do`

Uses the authors' supplied `bz_oecd_data.csv` to reproduce Figure 7.

**Outputs:**
- `output/01_replication/figure7a.pdf`
- `output/01_replication/figure7b.pdf`

### Step 02 — Data reconstruction

**R script:** `my_code/data_preparation/step1_bz_dummies.R`

Converts the narrative pension reform data into numerical reform variables.

**Stata script:** `output/02_data_preparation/stata_work/step2_construct_bz_data.do`

Combines reform variables with the macroeconomic and demographic data to reconstruct the analysis dataset.

**Outputs:**
- `output/02_data_preparation/Dummy.csv`
- `output/02_data_preparation/bz_oecd_data.csv`

Both reconstructed datasets were compared with the authors' supplied files. Each dataset contained 590 observations, and all columns and data values matched.

### Step 03 — Figure 7 using the reconstructed dataset

**Script:** `my_code/replicate_figure7_reconstructed.do`

Uses my reconstructed `bz_oecd_data.csv` to reproduce Figure 7 again.

**Outputs:**
- `output/03_reconstructed/figure7a.pdf`
- `output/03_reconstructed/figure7b.pdf`

The reproduced figures were visually consistent with the original results.

### Step 04 — Extension: Sample-period sensitivity

**Script:** `my_code/extension_1990.do`

Uses the reconstructed dataset and changes the sample starting year while keeping the Local Projection specification and controls unchanged.

| | Baseline | Extension |
|---|---|---|
| Code sample start | 1978 | 1990 |
| Nominal regression period | 1980–2017 | 1992–2017 |
| Maximum lags | 2 | 2 |
| Horizon | 10 years | 10 years |

**Outputs:**
- `output/04_extension_1990/figure7a_1990.pdf`
- `output/04_extension_1990/figure7b_1990.pdf`

## 4. Main Findings

The reproduced Figure 7 graphs closely resemble the published figures.

In the extension, the positive estimated effect of immediate pension reforms on labour force participation among workers aged 60–64 becomes weaker in the shorter sample.

The estimated response of pension spending relative to GDP also changes, including a change in direction.

These findings suggest sensitivity to the sample period. However, the differences between the estimates have not been formally tested for statistical significance.

## 5. Limitations

The paper does not provide a complete numerical coefficient table for Figure 7, so exact agreement between estimated coefficients and the published figures could not be independently verified.

The extension uses a shorter sample, which may reduce estimation precision and change the composition of observed pension reforms.

This project focuses on Figure 7 rather than replicating every result in the paper.