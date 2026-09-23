# Recreate every column of Cooper et al.'s coded dataset, as far as
# possible, purely from metacheck's own repo_check/data_check/code_check
# output (01_run_metacheck/res_*.RData) -- NOT open_practices/ODDPub,
# which measure a different, judgement-based question (see
# 04_build_master_comparison.R's own note on this). This is a direct,
# mechanical column-by-column reconstruction, built from an explicit
# specification (each mc_* column's derivation rule was given, not
# inferred) so every choice below is traceable back to that rule rather
# than to a guess about what "counts."
#
# This script and its output are self-contained within this folder: it
# reads only from 01_run_metacheck/ and this folder's own local files
# (sample.csv, BES-data-code-hackathon-cleaned_2025-12-01.csv), and
# writes only into this folder. It does not read or write anything in
# manuscript/data/ or manuscript/final_pipeline/.
#
# Cooper's own column, and what mc_* recreates it from:
#   data_availability -> a repo_check-listed repository exists, AND at
#     least one of its files was classified as tabular data
#   data_archive      -> WHERE the data lives (platform name, from the
#     repo_url, e.g. "Dryad") for whichever repository holds the data
#   data_doi          -> the DOI metacheck resolved for that repository
#     (repo_check's repo_metadata)
#   data_license      -> whether repo_check found a licence for that
#     repository (repo_metadata$license present)
#   data_download     -> whether the tabular data file(s) actually
#     downloaded AND could be opened with standard software (i.e.
#     data_check's own tabular_usable flag, not just file_location
#     being non-NA -- a file can download and still fail to parse)
#   data_format       -> file extensions of every tabular data file
#   data_README/code_README -> collapsed into one any_readme signal:
#     metacheck records a single README signal per paper (repo_check's
#     doc_role == "readme"), not separately for data vs. code, so it is
#     compared against cooper_any_readme (TRUE if Cooper's coders said
#     "Yes"/"Quasi-README" to EITHER of their two questions) rather than
#     double-counting one signal against two Cooper columns.
#   code_used         -> NOT classified by metacheck -- left NA
#   code_archived     -> whether repo_check-listed files for this paper
#     include at least one file code_check classified as code
#   code_download     -> whether that code file's file_location is
#     non-NA
#   code_language     -> code_check's own `language` column
#
# Usage (from inside manuscript/): Rscript 02_create_comparison_data/01_recreate_cooper_columns.R
library(dplyr)
library(metacheck)

source("02_create_comparison_data/helpers.R")

# == Step A: recreate Cooper's columns from metacheck's own output ==================

status("Loading corpus-wide repo_check/data_check/code_check results...")
load("01_run_metacheck/res_repo_check.RData")
load("01_run_metacheck/res_data_check.RData")
load("01_run_metacheck/res_code_check.RData")

structure_table <- res_data_check$structure |>
  .ensure_cols(list(paper_id = character(), repo_url = character(),
                    file_location = character(), data_type = character(),
                    data_format = character(), tabular_usable = logical()))

repo_table <- res_repo_check$table |>
  .ensure_cols(list(paper_id = character(), repo_url = character(),
                    doc_role = character()))

.first_non_na <- function(x) {
  x <- stats::na.omit(x)
  if (length(x) == 0) NA_character_ else x[[1]]
}
repo_metadata <- if ("repo_metadata" %in% names(res_repo_check))
  res_repo_check$repo_metadata |>
    summarise(doi = .first_non_na(doi), license = .first_non_na(license),
              .by = repo_url) else
  data.frame(repo_url = character(0), doi = character(0), license = character(0))

# One row per paper's DATA-holding repository: the repo_url that has at
# least one tabular-data-classified file, per paper.
data_repos <- structure_table |>
  filter(data_type == "data") |>
  distinct(paper_id, repo_url)

# "Does a data repository exist at all" uses repo_check's own file count
# (files_n > 0 on the summary_table), not data_check's narrower
# data-classification -- a repository existing is a repo_check question.
mc_data_availability <- res_repo_check$summary_table |>
  summarise(mc_data_availability = any(files_n > 0, na.rm = TRUE), .by = paper_id)

# Platform-name matching for mc_data_archive: matches BOTH the
# platform's own domain and its DOI prefix reached via doi.org (repo_url
# stores the doi.org form far more often than the platform's own
# domain). Dryad and Figshare match every known alternate DOI prefix and
# institutional host metacheck itself recognises (.dryad_doi_prefixes(),
# .figshare_vanity_hosts(), .figshare_doi_prefix_hosts()), not just the
# single most common literal for each -- read directly from metacheck's
# own lists so this classification cannot drift out of sync with what it
# recognises.
.dryad_url_regex <- paste0(
  "datadryad\\.org|(?:",
  paste(gsub("\\.", "\\\\.", metacheck:::.dryad_doi_prefixes()), collapse = "|"),
  ")/"
)
.figshare_url_regex <- paste0(
  "figshare\\.com|10\\.6084/m9\\.figshare|(?:",
  paste(gsub("\\.", "\\\\.", metacheck:::.figshare_vanity_hosts()), collapse = "|"),
  ")|(?:",
  paste(gsub("\\.", "\\\\.", names(metacheck:::.figshare_doi_prefix_hosts())), collapse = "|"),
  ")/"
)
.repo_url_platform <- function(url) {
  dplyr::case_when(
    is.na(url) ~ NA_character_,
    grepl("osf\\.io", url, ignore.case = TRUE) ~ "OSF",
    grepl("github\\.com|gitlab\\.com", url, ignore.case = TRUE) ~ "GitHub, GitLab, Codeberg or similar platform",
    grepl("zenodo\\.org|10\\.5281/zenodo", url, ignore.case = TRUE) ~ "Zenodo",
    grepl(.dryad_url_regex, url, ignore.case = TRUE, perl = TRUE) ~ "Dryad",
    grepl(.figshare_url_regex, url, ignore.case = TRUE, perl = TRUE) ~ "Figshare",
    TRUE ~ "Other repo/database"
  )
}
mc_data_archive <- data_repos |>
  mutate(platform = .repo_url_platform(repo_url)) |>
  summarise(mc_data_archive = paste(sort(unique(platform)), collapse = ";"), .by = paper_id)

mc_data_doi <- data_repos |>
  left_join(repo_metadata |> select(repo_url, doi), by = "repo_url") |>
  filter(!is.na(doi)) |>
  summarise(mc_data_doi = paste(sort(unique(doi)), collapse = ";"), .by = paper_id)

mc_data_license <- data_repos |>
  left_join(repo_metadata |> select(repo_url, license), by = "repo_url") |>
  summarise(mc_data_license = any(!is.na(license)), .by = paper_id)

# "Downloaded AND opened successfully with standard software" (Cooper's
# own data_download wording) requires file_location non-NA (genuinely
# fetched) AND tabular_usable TRUE (parsed successfully) together --
# tabular_usable alone is not a usable signal on its own. Computed
# directly over structure_table's own per-file rows, not joined through
# data_repos by repo_url -- a file's own file_location/tabular_usable
# already carries everything this needs.
mc_data_download <- structure_table |>
  filter(data_type == "data", !is.na(file_location), nzchar(file_location)) |>
  summarise(mc_data_download = any(tabular_usable %in% TRUE), .by = paper_id)

# File extensions of every tabular file -- NOT data_check's own
# `data_format` column, which despite the name is a coarse
# raw-vs-tabular structural category (values are only
# "raw"/"tabular"/NA, never an extension). Extract the extension from
# file_name directly instead, restricted to files data_check itself
# judged tabular_usable (matching mc_data_download's own "genuinely
# usable tabular data" scope, not just anything data-typed).
mc_data_format <- structure_table |>
  filter(data_type == "data", tabular_usable %in% TRUE) |>
  mutate(ext = tolower(sub("^.*(\\.[A-Za-z0-9]+)$", "\\1", file_name))) |>
  filter(nzchar(ext), startsWith(ext, ".")) |>
  summarise(mc_data_format = paste(sort(unique(ext)), collapse = ";"), .by = paper_id)

mc_readme <- repo_table |>
  summarise(mc_readme_present = any(doc_role == "readme", na.rm = TRUE), .by = paper_id)

code_table <- res_code_check$table |>
  .ensure_cols(list(paper_id = character(), repo_url = character(),
                    file_location = character(), language = character()))

mc_code_archived <- code_table |>
  summarise(mc_code_archived = dplyr::n() > 0, .by = paper_id)

mc_code_download <- code_table |>
  summarise(mc_code_download = any(!is.na(file_location) & nzchar(file_location)),
            .by = paper_id)

mc_code_language <- code_table |>
  filter(!is.na(language), nzchar(language)) |>
  summarise(mc_code_language = paste(sort(unique(language)), collapse = ";"), .by = paper_id)

# summary_table's paper_id (not the three per-file tables) is the full
# corpus by construction -- a paper repo_check found zero files for has
# no row at all in any per-file table, and using only those tables here
# would silently drop such papers from the comparison entirely instead
# of correctly scoring them FALSE.
all_paper_ids <- unique(c(res_repo_check$summary_table$paper_id,
                          structure_table$paper_id, code_table$paper_id, repo_table$paper_id))

recreated <- data.frame(paper_id = all_paper_ids, stringsAsFactors = FALSE) |>
  left_join(mc_data_availability, by = "paper_id") |>
  left_join(mc_data_archive,      by = "paper_id") |>
  left_join(mc_data_doi,          by = "paper_id") |>
  left_join(mc_data_license,      by = "paper_id") |>
  left_join(mc_data_download,     by = "paper_id") |>
  left_join(mc_data_format,       by = "paper_id") |>
  left_join(mc_readme |> rename(mc_data_README = mc_readme_present), by = "paper_id") |>
  mutate(mc_code_used = NA) |>
  left_join(mc_code_archived,     by = "paper_id") |>
  left_join(mc_code_download,     by = "paper_id") |>
  left_join(mc_code_language,     by = "paper_id") |>
  left_join(mc_readme |> rename(mc_code_README = mc_readme_present), by = "paper_id")

# "No repository/file found at all" has a definitive FALSE for existence
# columns (repo_check ran and found nothing) -- left NA for every other
# mc_* column (license, DOI, download, format, language), which are
# legitimately not answerable when there is no repository to ask about.
for (col in c("mc_data_availability", "mc_code_archived", "mc_data_README", "mc_code_README")) {
  recreated[[col]][is.na(recreated[[col]])] <- FALSE
}

# Saved as .rds, not .RData: recreated is a single plain dataframe, so
# .rds (readRDS() into any variable name) is the right format for a
# single tabular object.
saveRDS(recreated, file = "02_create_comparison_data/recreated_cooper_columns.rds")
status("Recreated %d columns for %d papers -> 02_create_comparison_data/recreated_cooper_columns.rds",
       ncol(recreated) - 1, nrow(recreated))

# == Step B: join onto Cooper's real columns for a side-by-side look ================
# Cooper's CSV is read from this folder's own local copy
# (BES-data-code-hackathon-cleaned_2025-12-01.csv) -- already downloaded
# here rather than fetched fresh from GitHub on every run, so this
# script has no network dependency and is reproducible from a fixed,
# versioned snapshot of Cooper et al.'s coding.
status("Loading Cooper et al.'s coded ground truth...")
cooper <- read.csv(
  "02_create_comparison_data/BES-data-code-hackathon-cleaned_2025-12-01.csv",
  na.strings = "NA", stringsAsFactors = FALSE
)
cooper <- .fix_invalid_utf8(cooper)

# Cooper et al.'s coded CSV has 4 DOIs each mistakenly copy-pasted onto
# TWO different papers (confirmed by cross-referencing paper_number --
# unique, never duplicated -- against the master metadata list: for all
# 8 affected rows the coder's own recorded journal matches that
# paper_number's TRUE journal, so only the doi field was wrong on one
# row of each pair). Uncorrected, both rows of each pair map to the SAME
# article_id via sample.csv's doi-keyed lookup below, producing a
# many-to-many join and duplicate rows. sample.csv itself already
# reflects the corrected DOIs -- this must be applied here too, to this
# freshly loaded copy of cooper, so this script's join uses the same
# corrected DOIs sample.csv was keyed on.
.DOI_CORRECTIONS <- data.frame(
  paper_number = c("57", "1275", "47", "7176"),
  correct_doi  = c("10.1002/2688-8319.12136", "10.1111/1365-2656.13512",
                   "10.1111/1365-2656.13145", "10.1111/1365-2435.12981"),
  stringsAsFactors = FALSE
)
m <- match(as.character(cooper$paper_number), .DOI_CORRECTIONS$paper_number)
fix <- !is.na(m)
if (any(fix)) cooper$doi[fix] <- .DOI_CORRECTIONS$correct_doi[m[fix]]

sampled <- read.csv("02_create_comparison_data/sample.csv", colClasses = "character")
doi_to_article_id <- setNames(sampled$article_id, tolower(sampled$doi))
cooper$article_id <- doi_to_article_id[tolower(cooper$doi)]

side_by_side <- cooper |>
  select(article_id, data_availability, data_archive, data_doi, data_license,
         data_download, data_format, data_README,
         code_used, code_archived, code_download, code_language, code_README) |>
  left_join(recreated, by = c("article_id" = "paper_id"))

# any_readme: collapsed data_README OR code_README vs. the one repo_check
# readme signal metacheck actually has.
.cooper_bool <- function(x, positive, negative) {
  out <- rep(NA, length(x))
  out[x %in% positive] <- TRUE
  out[x %in% negative] <- FALSE
  out
}
data_readme_bool <- .cooper_bool(side_by_side$data_README, c("Yes", "Quasi-README"), "No")
code_readme_bool <- .cooper_bool(side_by_side$code_README, c("Yes", "Quasi-README"), "No")
side_by_side$cooper_any_readme <- ifelse(
  !is.na(data_readme_bool) & data_readme_bool, TRUE,
  ifelse(!is.na(code_readme_bool) & code_readme_bool, TRUE,
  ifelse(is.na(data_readme_bool) & is.na(code_readme_bool), NA, FALSE)))
side_by_side$mc_any_readme <- side_by_side$mc_data_README

# Saved as .rds, not .RData: side_by_side is a single plain dataframe --
# see the comment on recreated's own save() above.
saveRDS(side_by_side, file = "02_create_comparison_data/cooper_vs_recreated.rds")
status("Side-by-side Cooper vs. recreated columns -> 02_create_comparison_data/cooper_vs_recreated.rds")
