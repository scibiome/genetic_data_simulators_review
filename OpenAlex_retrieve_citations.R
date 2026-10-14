library(readxl)
library(httr)
library(jsonlite)
library(dplyr)
library(purrr)
library(stringr)

# -----------------------------
# 1. READ EXCEL FILE
# -----------------------------

df <- read_excel("./papers_included_doi.xlsx")

# -----------------------------
# 2. CLEAN DOI COLUMN
# -----------------------------

df <- df %>%
  mutate(
    DOI = str_trim(DOI),
    DOI = str_replace_all(DOI, "[\r\n]", ""),   # remove line breaks
    DOI = str_remove(DOI, "^https://doi.org/")  # keep only raw DOI
  )

# -----------------------------
# 3. FUNCTION TO QUERY OPENALEX
# -----------------------------
get_citations <- function(tool, doi, strategy){
  
  doi_clean <- tolower(gsub("^https?://doi.org/", "", doi))
  
  # ---- SLiM 2 exception: replace DOI with OpenAlex ID ----
  if(doi == "10.1093/molbev/msw211"){
    doi_clean <- "W2529123163"
    url <- paste0("https://api.openalex.org/works/", doi_clean)
  } else {
    url <- paste0("https://api.openalex.org/works/doi:", doi_clean)
  }
  
  print(url)
  
  # safe API request
  res <- try(httr::GET(url), silent = TRUE)
  print(res)
  
  if(inherits(res, "try-error")){
    message("Request failed for: ", tool)
    return(NULL)
  }
  
  if(res$status_code != 200){
    message("API error for: ", tool)
    return(NULL)
  }
  
  data <- jsonlite::fromJSON(httr::content(res, "text", encoding="UTF-8"))
  
  pub_year <- data$publication_year
  title <- data$title
  
  citations <- data$counts_by_year
  print(data$counts_by_year)
  
  if(is.null(citations) || length(citations) == 0) return(NULL)
  
  citations %>%
    dplyr::select(year, cited_by_count) %>%
    dplyr::rename(
      Year = year,
      Citations = cited_by_count
    ) %>%
    dplyr::mutate(
      Tool = tool,
      Publication_Year = pub_year,
      Paper_Title = title,
      Strategy = strategy
    ) %>%
    dplyr::select(
      Tool,
      Publication_Year,
      Paper_Title,
      Strategy,
      Year,
      Citations
    )
}

# -----------------------------
# 4. LOOP THROUGH ALL PAPERS
# -----------------------------

results <- purrr::pmap_dfr(
  list(df$Tool, df$DOI, df$Strategy),
  get_citations
)

# -----------------------------
# 5. SAVE RESULTS
# -----------------------------

write.csv(results, "tool_citation_history.csv", row.names = FALSE)


