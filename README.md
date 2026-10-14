# Genetic Data Simulation: Retrospective Insights and Future Directions

This repository contains the data and R scripts for the citation analysis in the review *"Genetic Data Simulation: Retrospective Insights and Future Directions"*.

The review covers simulation tools for genetic data published since 2011. For each forward-time, backward-time (coalescent) and resampling-based tool discussed in the review, we retrieved the tool's annual citation counts from [OpenAlex](https://openalex.org/) and analysed the cumulative citations over time.

The workflow has two steps:

1. `OpenAlex_retrieve_citations.R`: Reads the list of publications (`papers_included_doi.xlsx`), queries the OpenAlex API for each DOI and writes the annual citation counts to `tool_citation_history.csv`.
2. `Citation_Analysis.R`: Reads `tool_citation_history.csv`, performs the citation analysis and generates the figure presented in the manuscript. Citations of different versions of the same tool (e.g. SLiM 1–5) are merged and counted as one tool.

Data:
- `papers_included_doi.xlsx`: Contains the publications included in the review, along with their associated Digital Object Identifiers (DOIs).
- `tool_citation_history.csv`: Contains annual citation counts for the publications associated with the reviewed tools.

## Repository Contents

| File | Description |
| --- | --- |
| `papers_included_doi.xlsx` | Input: the 35 tool publications included in the citation analysis, with DOI and simulation strategy |
| `OpenAlex_retrieve_citations.R` | Step 1: retrieves annual citation counts from the OpenAlex API |
| `tool_citation_history.csv` | Output of step 1 / input of step 2: annual citation counts per publication, as used in the manuscript |
| `Citation_Analysis.R` | Step 2: aggregates the citation counts and creates the figure |
| `figure_cumulative_citations.png` | Output of step 2: figure as PNG |
| `figure_cumulative_citations.pdf` | Output of step 2: figure as PDF |

## Setup

The scripts require [R](https://www.r-project.org/) (developed with R 4.4.2) and the following packages:

```r
install.packages(c("readxl", "httr", "jsonlite", "dplyr", "purrr", "stringr",
                   "readr", "tidyr", "ggplot2", "ggrepel", "scales", "patchwork"))
```

| Script | Required packages |
| --- | --- |
| `OpenAlex_retrieve_citations.R` | readxl, httr, jsonlite, dplyr, purrr, stringr |
| `Citation_Analysis.R` | dplyr, readr, tidyr, ggplot2, ggrepel, scales, patchwork |

## Usage

Both scripts use relative paths, so run them from the root of the repository:

```bash
git clone https://github.com/scibiome/genetic_data_simulators_review.git
cd genetic_data_simulators_review

# Step 1 (optional): retrieve current citation counts from OpenAlex
Rscript OpenAlex_retrieve_citations.R

# Step 2: create the figure
Rscript Citation_Analysis.R
```

To reproduce the manuscript figure, run only step 2. Step 1 overwrites `tool_citation_history.csv` with current citation counts, replacing the data used in the manuscript.

## Reproducibility

The R scripts are provided to document the citation data retrieval and analysis workflow and to facilitate reproducibility of the results.

Because citation counts can change over time as new publications are indexed, rerunning the citation retrieval script may produce results that differ from those used in the manuscript.

## Reference

Grabert G\*, Thoben C\*, Müller N, Nowak F, Kacprowski T. Genetic Data Simulation: Retrospective Insights and Future Directions. 2026. DOI will be added upon publication.

\* These authors contributed equally.