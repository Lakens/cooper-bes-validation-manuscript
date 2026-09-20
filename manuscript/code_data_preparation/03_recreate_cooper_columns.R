# Recreate every column of Cooper et al.'s coded dataset, as far as
# possible, purely from metacheck's own repo_check/data_check/code_check
# output -- NOT open_practices/ODDPub, which measure a different,
# judgement-based question (see 02_compare_to_cooper.R's own note on
# this). This is a direct, mechanical column-by-column reconstruction,
# built from an explicit specification (each mc_* column's derivation
# rule was given, not inferred) so every choice below is traceable back
# to that rule rather than to a guess about what "counts."
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
#   data_README       -> whether repo_check found a readme (doc_role ==
#     "readme") -- the SAME signal code_README below uses; a repository-
#     level readme, not separate per data/code
#   code_used         -> NOT classified by metacheck (no module answers
#     "did this paper use code" as opposed to "is there a code file
#     sitting in the repository") -- left NA throughout, as specified
#   code_archived     -> whether repo_check-listed files for this paper
#     include at least one file code_check classified as code
#   code_download     -> whether that code file's file_location is
#     non-NA (code_check has no separate "openable" flag the way
#     data_check's tabular_usable does; "downloaded" is the whole check)
#   code_language     -> code_check's own `language` column
#   code_README       -> the SAME repo_check readme signal as
#     data_README (Cooper's own protocol also describes this as one
#     "is there a README in the repository" question asked once per
#     paper, not separately worded for data vs. code)
#
# Usage: Rscript 03_recreate_cooper_columns.R

library(dplyr)

source("code_data_preparation/helpers.R")

status("Loading corpus-wide repo_check/data_check/code_check results...")
load("data/res_repo_check.RData")
load("data/res_data_check.RData")
load("data/res_code_check.RData")

# == Platform name from a repo_url, for data_archive =================================
# Same mapping 02_compare_to_cooper.R uses for mc_repo_types, restated
# here with Cooper's own capitalisation/wording where their data_archive
# column uses one (Dryad, Figshare, Zenodo, GitHub...) and "Other
# repo/database" for anything else, matching their own coding scheme's
# category rather than inventing a new label.
#
# Matches BOTH the platform's own domain (zenodo.org, figshare.com, ...)
# AND its DOI prefix reached via doi.org (10.5281/zenodo.<id>,
# 10.6084/m9.figshare.<id>, ...) -- repo_check's own repo_url is
# confirmed to store the doi.org form for these platforms far more often
# than the platform's own domain (same pattern already correctly
# handled for Dryad below before this fix; Zenodo/Figshare were missing
# their own DOI-prefix cases, which meant EVERY doi.org/10.5281/zenodo...
# URL silently fell through to "Other repo/database" instead of "Zenodo"
# -- confirmed live: 114 of 811 flagged data_archive disagreements were
# this exact false mismatch, not a real metacheck-vs-Cooper difference).
#
# Dryad's own branch had the identical bug in miniature: it only matched
# the single, most common prefix (10.5061), not the 13 other DOI prefixes
# Dryad has minted datasets under over the years and metacheck's own
# dryad_links()/.dryad_doi_prefixes() has recognised since this session's
# earlier fix (10.15146, 10.25338, 10.25349, 10.5068, 10.6071, 10.6075,
# 10.6076, 10.6078, 10.6086, 10.7272, 10.7280, 10.7291, 10.7941) -- found
# live 2026-09-19 via 9 papers whose repository WAS correctly found and
# retrieved (repo_check no longer "never located" them) but still showed
# a data_archive disagreement, because this classification fell through
# to "Other repo/database" for a real Dryad DOI under one of these other
# prefixes. Sourced directly from metacheck's own
# .dryad_doi_prefixes() rather than duplicating the list by hand, so this
# branch never drifts out of sync with what dryad_links() itself
# recognises again.
.dryad_url_regex <- paste0(
  "datadryad\\.org|(?:",
  paste(gsub("\\.", "\\\\.", metacheck:::.dryad_doi_prefixes()), collapse = "|"),
  ")/"
)
# Same fix as the Dryad branch above, for the identical reason: hardcoding
# only figshare.com/10.6084 missed every institutional Figshare instance
# added to metacheck's .figshare_vanity_hosts()/.figshare_doi_prefix_hosts()
# in PR #414 (2026-09-19) -- found live via a real paper whose Melbourne
# Figshare deposit (10.26188) repo_check now correctly finds and
# retrieves, but data_archive still fell through to "Other repo/database"
# because this classification only recognised the generic figshare.com
# domain/prefix. Sourced from metacheck's own lists so this branch cannot
# drift out of sync with what figshare_links() itself recognises again.
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

# == Data-side columns, from data_check$structure + repo_check =======================

structure_table <- res_data_check$structure |>
  .ensure_cols(list(paper_id = character(), repo_url = character(),
                    file_location = character(), data_type = character(),
                    data_format = character(), tabular_usable = logical()))

repo_table <- res_repo_check$table |>
  .ensure_cols(list(paper_id = character(), repo_url = character(),
                    doc_role = character()))

# repo_metadata is not guaranteed one row per repo_url (confirmed live:
# a many-to-many join warning surfaced a repo_url with more than one
# metadata row, likely a dataset with more than one resolved version) --
# collapse to one row per repo_url before joining, taking the first
# non-NA doi/license (NA if every row for that repo_url is NA), so a
# paper cannot get duplicated by this join.
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
# least one tabular-data-classified file, per paper. A paper can in
# principle have more than one such repository (e.g. two Dryad
# datasets) -- collapse to one row per paper the same way Cooper's own
# single-row-per-paper coding does, by taking all of them (semicolon-
# joined for data_archive/data_doi, as the master comparison does for
# mc_repo_types/mc_licence_type elsewhere in this pipeline).
data_repos <- structure_table |>
  filter(data_type == "data") |>
  distinct(paper_id, repo_url)

# "Does a data repository exist at all" (Cooper's data_availability
# question) is NOT the same question as "did data_check classify one of
# its files as tabular data" -- confirmed live 2026-09-02 against 50
# manually-reviewed disagreements, ALL 50 of which were this exact bug:
# repo_check correctly found and listed the repository (e.g. a real,
# working Dryad DOI resolving to a single file), but that file was a
# .zip archive, so data_check classified it as "unknown" (peek_zips
# defaults to FALSE -- it never opens the zip to see what's inside), and
# the old logic here (any(data_type == "data")) required a "data"
# classification specifically. A repository existing is a repo_check
# question, not a data_check one -- use repo_check's own file count
# instead, matching mc_repo_files_found's logic in
# 02_compare_to_cooper.R (files_n > 0 on the summary_table) rather than
# re-deriving it from data_check's narrower, stricter classification.
mc_data_availability <- res_repo_check$summary_table |>
  summarise(mc_data_availability = any(files_n > 0, na.rm = TRUE), .by = paper_id)

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

# tabular_usable DEFAULTS TO TRUE regardless of data_type/file_location
# -- confirmed live: 3000 of 3171 rows in a real batch show TRUE despite
# never having been downloaded at all (file_location NA). It is only
# meaningfully computed (occasionally FALSE) for a file that is BOTH
# data-typed AND was actually downloaded and inspected. So "downloaded
# AND opened successfully with standard software" (Cooper's own
# data_download wording) requires file_location non-NA (genuinely
# fetched) AND tabular_usable TRUE (parsed successfully) together --
# tabular_usable alone is not a usable signal on its own.
mc_data_download <- structure_table |>
  filter(data_type == "data", !is.na(file_location), nzchar(file_location)) |>
  summarise(mc_data_download = any(tabular_usable %in% TRUE), .by = paper_id)

# File extensions of every tabular file -- NOT data_check's own
# `data_format` column, which despite the name is a coarse
# raw-vs-tabular structural category (confirmed live: values are only
# "raw"/"tabular"/NA, never an extension). Extract the extension from
# file_name directly instead, restricted to files data_check itself
# judged tabular_usable (matching mc_data_download's own "genuinely
# usable tabular data" scope, not just anything data-typed).
mc_data_format <- structure_table |>
  filter(data_type == "data", tabular_usable %in% TRUE) |>
  mutate(ext = tolower(sub("^.*(\\.[A-Za-z0-9]+)$", "\\1", file_name))) |>
  filter(nzchar(ext), startsWith(ext, ".")) |>
  summarise(mc_data_format = paste(sort(unique(ext)), collapse = ";"), .by = paper_id)

# == README, shared by data and code (repo_check's own readme signal) ================

mc_readme <- repo_table |>
  summarise(mc_readme_present = any(doc_role == "readme", na.rm = TRUE), .by = paper_id)

# == Code-side columns, from code_check$table =========================================

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

# == Assemble one row per paper, matching Cooper's own paper_id (article_id) =========

# Base this on summary_table's paper_id, not the three per-FILE tables
# (structure_table/code_table/repo_table) -- repo_check runs on and
# reports a summary_table row for EVERY paper, but a paper repo_check
# found zero files for has no row at all in any per-file table. Using
# only the per-file tables here meant those papers were silently absent
# from `recreated` entirely, so the FALSE defaults below never reached
# them -- confirmed live: 495 of 1861 papers ended up with
# mc_data_availability NA (not FALSE), including 404 papers Cooper coded
# data_availability "Yes", which 04_column_agreement.R's n-both-non-NA
# comparison then silently excluded instead of counting as a real
# disagreement. summary_table$paper_id is already the full 1861 by
# construction; the union with the per-file tables is just defensive.
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
  mutate(mc_code_used = NA) |>  # not classified by metacheck -- see header comment
  left_join(mc_code_archived,     by = "paper_id") |>
  left_join(mc_code_download,     by = "paper_id") |>
  left_join(mc_code_language,     by = "paper_id") |>
  left_join(mc_readme |> rename(mc_code_README = mc_readme_present), by = "paper_id")

# Columns where "no repository/file found at all" has a definitive TRUE/
# FALSE answer (repo_check ran and found nothing) rather than being
# genuinely inapplicable: existence (mc_data_availability,
# mc_code_archived) and the shared README signal (both come from
# repo_table, the same per-file table that is absent for a zero-file
# paper, so they share the identical gap). Left at NA for every OTHER
# mc_* column (license, DOI, download, format, language) -- those are
# legitimately not answerable when there is no repository to ask about,
# matching how 04_column_agreement.R's NA-on-either-side exclusion is
# meant to work for genuinely inapplicable columns.
for (col in c("mc_data_availability", "mc_code_archived", "mc_data_README", "mc_code_README")) {
  recreated[[col]][is.na(recreated[[col]])] <- FALSE
}

save(recreated, file = "data/recreated_cooper_columns.RData")
status("Recreated %d columns for %d papers -> data/recreated_cooper_columns.RData",
       ncol(recreated) - 1, nrow(recreated))

cat("\nColumn preview:\n")
print(utils::head(recreated))

# == Join onto Cooper's real columns for a side-by-side look =========================

cooper <- read.csv(
  "https://raw.githubusercontent.com/nhcooper123/reproduce-reuse-recycle/main/data/BES-data-code-hackathon-cleaned_2025-12-01.csv",
  na.strings = "NA", stringsAsFactors = FALSE
)
cooper <- .fix_invalid_utf8(cooper)  # see helpers.R -- a few cells have invalid UTF-8 bytes
sampled <- read.csv("../sample.csv", colClasses = "character")
doi_to_article_id <- setNames(sampled$article_id, tolower(sampled$doi))
cooper$article_id <- doi_to_article_id[tolower(cooper$doi)]

side_by_side <- cooper |>
  select(article_id, data_availability, data_archive, data_doi, data_license,
         data_download, data_format, data_README,
         code_used, code_archived, code_download, code_language, code_README) |>
  left_join(recreated, by = c("article_id" = "paper_id"))

save(side_by_side, file = "data/cooper_vs_recreated.RData")
status("Side-by-side Cooper vs. recreated columns -> data/cooper_vs_recreated.RData")
