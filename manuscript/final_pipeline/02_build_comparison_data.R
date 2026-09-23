# Derive metacheck's mc_*-prefixed columns from the module output that
# 01_run_metacheck.R produced, join them against Cooper et al.'s own
# coded ground truth, write the disagreement worklist as a data file
# (data/disagreement_review_worklist.rds, code-generated, no manual
# content) plus a spreadsheet for manual review
# (data/disagreement_review_worklist.xlsx, see final_pipeline/README.md),
# and compute the comparison statistics the manuscript reports.
# Rerunning this script after the worklist has been manually reviewed
# recomputes the statistics from whatever verdicts are present; it never
# overwrites an existing xlsx row's _verdict/_comment (see the note
# before the worklist-writing step below).
#
# Cooper's own column, and what mc_* recreates it from:
#   data_availability -> a repo_check-listed repository exists, AND at
#     least one of its files was classified as tabular data
#   data_archive      -> WHERE the data lives (platform name, from the
#     repo_url, e.g. "Dryad") for whichever repository holds the data
#   data_doi          -> the DOI metacheck resolved for that repository
#   data_license      -> whether repo_check found a licence for that
#     repository
#   data_download     -> whether the tabular data file(s) actually
#     downloaded AND could be opened with standard software
#   data_format       -> file extensions of every tabular data file
#   data_README/code_README -> collapsed into one any_readme signal:
#     metacheck records a single README signal per paper (repo_check's
#     doc_role == "readme"), not separately for data vs. code, so we
#     compare it against cooper_any_readme (TRUE if Cooper's coders
#     said "Yes"/"Quasi-README" to EITHER of their two questions) rather
#     than double-counting one signal against two Cooper columns.
#   code_used         -> NOT classified by metacheck -- left NA
#   code_archived     -> whether repo_check-listed files for this paper
#     include at least one file code_check classified as code
#   code_download     -> whether that code file's file_location is
#     non-NA
#   code_language     -> code_check's own `language` column
#
# Usage (from inside manuscript/): Rscript final_pipeline/02_build_comparison_data.R
library(dplyr)
library(metacheck)

source("final_pipeline/helpers.R")

# == Step A: recreate Cooper's columns from metacheck's own output ==================

status("Loading corpus-wide repo_check/data_check/code_check results...")
load("data/res_repo_check.RData")
load("data/res_data_check.RData")
load("data/res_code_check.RData")

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
# .rds (readRDS() into any variable name) is the right format, per this
# repository's convention of never using .RData for a simple dataframe.
saveRDS(recreated, file = "data/recreated_cooper_columns.rds")
status("Recreated %d columns for %d papers -> data/recreated_cooper_columns.rds",
       ncol(recreated) - 1, nrow(recreated))

status("Loading Cooper et al.'s coded ground truth...")
cooper <- read.csv(
  "data/BES-data-code-hackathon-cleaned_2025-12-01.csv",
  na.strings = "NA", stringsAsFactors = FALSE
)
cooper <- .fix_invalid_utf8(cooper)
sampled <- read.csv("../sample.csv", colClasses = "character")
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
saveRDS(side_by_side, file = "data/cooper_vs_recreated.rds")
status("Side-by-side Cooper vs. recreated columns -> data/cooper_vs_recreated.rds")

# == Step B: build the disagreement worklist =========================================
# Split into two files so a `git diff` (or just eyeballing mtimes) shows
# whether the DATA changed (a metacheck rerun found different
# disagreements) or the human REVIEW changed (someone filled in a
# verdict/comment), instead of conflating both into one CSV:
#   - data/disagreement_review_worklist.rds: every disagreement row and
#     its data columns, entirely code-generated, overwritten fresh every
#     run.
#   - data/disagreement_review_worklist.xlsx: only row_id/article_id/
#     disagreements plus the 7 verdict/comment column pairs, manually
#     edited. Any other columns already present in this file (free-form
#     notes such as double_check_disagreements) are left untouched.
# 7 verdicted columns: data_availability, data_archive, data_license,
# data_download, code_archived, code_download, any_readme. data_archive
# is overlap-based (a paper can cite more than one repository, so any
# shared platform name counts as agreement); every other column is a
# straight boolean comparison.

bool_pairs <- list(
  data_availability = list(cooper = "data_availability", mc = "mc_data_availability",
                           positive = "Yes", negative = c("No", "No, but they are available on request")),
  data_license      = list(cooper = "data_license", mc = "mc_data_license",
                           positive = "Yes", negative = "No"),
  data_download     = list(cooper = "data_download", mc = "mc_data_download",
                           positive = c("Yes", "Yes, but not all data"), negative = "No"),
  code_archived     = list(cooper = "code_archived", mc = "mc_code_archived",
                           positive = "Yes", negative = "No"),
  code_download     = list(cooper = "code_download", mc = "mc_code_download",
                           positive = "Yes", negative = "No")
)

n <- nrow(side_by_side)
disagree_cols <- rep("", n)
flags <- list()
for (nm in names(bool_pairs)) {
  p <- bool_pairs[[nm]]
  cb <- .cooper_bool(side_by_side[[p$cooper]], p$positive, p$negative)
  mb <- side_by_side[[p$mc]]
  both <- !is.na(cb) & !is.na(mb)
  disagree <- both & (cb != mb)
  flags[[nm]] <- disagree
  direction <- ifelse(disagree, ifelse(cb, "cooper=Yes,mc=No", "cooper=No,mc=Yes"), NA)
  for (i in which(disagree)) {
    tag <- sprintf("%s[%s]", nm, direction[i])
    disagree_cols[i] <- if (nzchar(disagree_cols[i])) paste(disagree_cols[i], tag, sep = ";") else tag
  }
}

cv <- side_by_side$data_archive; mv <- side_by_side$mc_data_archive
da_both <- !is.na(cv) & !is.na(mv) & nzchar(cv) & nzchar(mv)
da_ov <- rep(NA, n)
da_ov[da_both] <- mapply(function(a, b) {
  sa <- trimws(strsplit(a, ";")[[1]]); sb <- trimws(strsplit(b, ";")[[1]])
  any(tolower(sa) %in% tolower(sb))
}, cv[da_both], mv[da_both])
da_disagree <- !is.na(da_ov) & !da_ov
flags[["data_archive"]] <- da_disagree
for (i in which(da_disagree)) {
  tag <- sprintf("data_archive[cooper=%s,mc=%s]", side_by_side$data_archive[i], side_by_side$mc_data_archive[i])
  disagree_cols[i] <- if (nzchar(disagree_cols[i])) paste(disagree_cols[i], tag, sep = ";") else tag
}

ar_disagree <- !is.na(side_by_side$cooper_any_readme) & !is.na(side_by_side$mc_any_readme) &
  (side_by_side$cooper_any_readme != side_by_side$mc_any_readme)
flags[["any_readme"]] <- ar_disagree
ar_dir <- ifelse(ar_disagree, ifelse(side_by_side$cooper_any_readme, "cooper=Yes,mc=No", "cooper=No,mc=Yes"), NA)
for (i in which(ar_disagree)) {
  tag <- sprintf("any_readme[%s]", ar_dir[i])
  disagree_cols[i] <- if (nzchar(disagree_cols[i])) paste(disagree_cols[i], tag, sep = ";") else tag
}

status("Disagreement counts by column:")
for (nm in names(flags)) status("  %-20s %d", nm, sum(flags[[nm]], na.rm = TRUE))

has_disagreement <- nzchar(disagree_cols)
review <- side_by_side[has_disagreement, ]
review$disagreements <- disagree_cols[has_disagreement]

dup <- duplicated(review$article_id) | duplicated(review$article_id, fromLast = TRUE)
review$row_id <- review$article_id
if (any(dup)) {
  ave_idx <- ave(seq_along(review$article_id), review$article_id, FUN = seq_along)
  review$row_id[dup] <- paste0(review$article_id[dup], "__dup", ave_idx[dup])
}
review <- review[, c("row_id", setdiff(names(review), "row_id"))]

verdict_cols <- c("data_availability", "data_archive", "data_license",
                  "data_download", "code_archived", "code_download", "any_readme")

RDS_PATH <- "data/disagreement_review_worklist.rds"
XLSX_PATH <- "data/disagreement_review_worklist.xlsx"

saveRDS(review, file = RDS_PATH)
status("Saved %s: %d disagreement rows (data only, regenerated fresh this run).",
       RDS_PATH, nrow(review))

build_key <- function(article_id, cooper_val, mc_val)
  paste(article_id, as.character(cooper_val), as.character(mc_val), sep = "")
cooper_col_for <- function(col) if (col == "data_archive") "data_archive" else
  if (col == "any_readme") "cooper_any_readme" else bool_pairs[[col]]$cooper
mc_col_for <- function(col) if (col == "data_archive") "mc_data_archive" else
  if (col == "any_readme") "mc_any_readme" else bool_pairs[[col]]$mc

for (col in verdict_cols) {
  review[[paste0(col, "_verdict")]] <- NA_character_
  review[[paste0(col, "_comment")]] <- NA_character_
}

# Carry forward already-recorded verdicts/comments for a (paper, column,
# cooper value, mc value) combination that is unchanged from a prior
# run -- reads from the xlsx (the human-edited file) primarily, and, only
# for cells the xlsx doesn't have, from the xlsx's own most recent CSV
# predecessor if still present, so review work already recorded before
# this rds/xlsx split existed is not lost.
`%||%` <- function(a, b) if (is.null(a)) b else a
carry_forward_from <- function(old, review) {
  for (col in verdict_cols) {
    vcol <- paste0(col, "_verdict"); ccol <- paste0(col, "_comment")
    if (!all(c(vcol, ccol) %in% names(old))) next
    cooper_col <- cooper_col_for(col); mc_col <- mc_col_for(col)
    if (!all(c(cooper_col, mc_col) %in% names(old))) next
    old_verdict <- old[[vcol]]
    has_old <- !is.na(old_verdict) & nzchar(trimws(old_verdict))
    if (!any(has_old)) next
    lut_key <- build_key(old$article_id, old[[cooper_col]], old[[mc_col]])[has_old]
    lut_verdict <- old_verdict[has_old]
    lut_comment <- old[[ccol]][has_old]
    first <- !duplicated(lut_key)
    lut_key <- lut_key[first]; lut_verdict <- lut_verdict[first]; lut_comment <- lut_comment[first]
    new_key <- build_key(review$article_id, review[[cooper_col]], review[[mc_col]])
    m <- match(new_key, lut_key)
    # Only fill cells still blank: a later source (xlsx) already wins
    # over an earlier one (old CSV) for any cell both provide.
    still_blank <- is.na(review[[vcol]]) | !nzchar(trimws(review[[vcol]] %||% ""))
    hit <- !is.na(m) & still_blank
    review[[vcol]][hit] <- lut_verdict[m[hit]]
    review[[ccol]][hit] <- lut_comment[m[hit]]
  }
  review
}

old_xlsx <- NULL
if (file.exists(XLSX_PATH)) {
  status("Existing xlsx worklist found -- carrying forward already-recorded verdicts.")
  old_xlsx <- as.data.frame(openxlsx::read.xlsx(XLSX_PATH), stringsAsFactors = FALSE)
  review <- carry_forward_from(old_xlsx, review)
}
OLD_CSV_PATH <- "data/disagreement_review_worklist.csv"
if (file.exists(OLD_CSV_PATH)) {
  status("Legacy CSV worklist found -- backfilling any verdicts missing from the xlsx.")
  old_csv <- read.csv(OLD_CSV_PATH, stringsAsFactors = FALSE)
  review <- carry_forward_from(old_csv, review)
}

disagreement_cols_by_len <- verdict_cols[order(-nchar(verdict_cols))]
flagged_cols_for_row <- function(disagreements_text) {
  if (is.na(disagreements_text) || !nzchar(disagreements_text)) return(character(0))
  disagreement_cols_by_len[vapply(disagreement_cols_by_len, function(col) {
    grepl(paste0("(^|;)", col, "\\["), disagreements_text)
  }, logical(1))]
}
review$reviewed <- vapply(seq_len(nrow(review)), function(i) {
  flagged <- flagged_cols_for_row(review$disagreements[i])
  if (length(flagged) == 0) return(NA)
  vcols <- paste0(flagged, "_verdict")
  all(!is.na(unlist(review[i, vcols])) & nzchar(trimws(unlist(review[i, vcols]))))
}, logical(1))

# The xlsx keeps only row_id/article_id/disagreements plus the 7
# verdict/comment pairs and `reviewed` -- everything else the script
# needs (the data columns joined into `review`, e.g. data_availability,
# mc_data_archive, cooper_any_readme, ...) lives only in the rds. Any
# OTHER columns already present in the old xlsx that are NOT one of
# review's own data columns -- free-form notes such as
# double_check_disagreements, or unused verdict/comment pairs from an
# earlier design such as data_format_verdict -- are carried forward
# untouched, matched by row_id, so manual annotations outside the
# script's own 7 columns are never dropped on a rewrite.
xlsx_core_cols <- c("row_id", "article_id", "disagreements", "reviewed",
                    as.vector(rbind(paste0(verdict_cols, "_verdict"), paste0(verdict_cols, "_comment"))))
xlsx_out <- review[, xlsx_core_cols]
if (!is.null(old_xlsx)) {
  extra_cols <- setdiff(names(old_xlsx), c(xlsx_core_cols, names(review)))
  if (length(extra_cols) > 0) {
    extra <- old_xlsx[match(xlsx_out$row_id, old_xlsx$row_id), extra_cols, drop = FALSE]
    xlsx_out <- cbind(xlsx_out, extra)
  }
}

openxlsx::write.xlsx(xlsx_out, XLSX_PATH, overwrite = TRUE)
status("Saved %s: %d rows, %d fully reviewed, %d awaiting manual review.",
       XLSX_PATH, nrow(xlsx_out), sum(xlsx_out$reviewed, na.rm = TRUE), sum(!xlsx_out$reviewed, na.rm = TRUE))

# == Step C: comparison statistics ==================================================
# Recomputed every time this script runs, from whatever verdicts are
# currently in `review` (already carries forward everything on disk, see
# Step B above) -- run again after manual review to update
# data/comparison_statistics.RData with the completed verdict tallies.

bool_pairs_stats <- c(bool_pairs, list())
labels <- c(data_availability = "Data availability", data_license = "Data licence present",
           data_download = "Data downloadable and usable", code_archived = "Code archived",
           code_download = "Code downloadable")

results <- list()
for (nm in names(bool_pairs_stats)) {
  p <- bool_pairs_stats[[nm]]
  cb <- .cooper_bool(side_by_side[[p$cooper]], p$positive, p$negative)
  mb <- side_by_side[[p$mc]]
  both <- !is.na(cb) & !is.na(mb)
  n_both <- sum(both)
  cb2 <- cb[both]; mb2 <- mb[both]

  tp <- sum(cb2 & mb2); fn <- sum(cb2 & !mb2); fp <- sum(!cb2 & mb2); tn <- sum(!cb2 & !mb2)
  sensitivity <- tp / (tp + fn); specificity <- tn / (tn + fp)
  ppv <- tp / (tp + fp); npv <- tn / (tn + fn)
  n_disagree <- fn + fp
  pct_cooper_caught_mc_missed <- if (n_disagree > 0) fn / n_disagree * 100 else NA
  pct_mc_caught_cooper_missed <- if (n_disagree > 0) fp / n_disagree * 100 else NA
  mcnemar <- if ((fn + fp) > 0) {
    tryCatch(mcnemar.test(matrix(c(tp, fn, fp, tn), nrow = 2), correct = TRUE), error = function(e) NULL)
  } else NULL

  results[[nm]] <- list(
    label = labels[[nm]] %||% nm,
    n_cooper_coded = sum(!is.na(cb)), n_mc_coded = sum(!is.na(mb)), n_both_coded = n_both,
    tp = tp, fn = fn, fp = fp, tn = tn,
    sensitivity = sensitivity, specificity = specificity, ppv = ppv, npv = npv,
    accuracy = (tp + tn) / n_both,
    n_agree = tp + tn, n_disagree = n_disagree, pct_agree = (tp + tn) / n_both * 100,
    pct_cooper_caught_mc_missed = pct_cooper_caught_mc_missed,
    pct_mc_caught_cooper_missed = pct_mc_caught_cooper_missed,
    mcnemar_stat = if (!is.null(mcnemar)) unname(mcnemar$statistic) else NA,
    mcnemar_df = if (!is.null(mcnemar)) unname(mcnemar$parameter) else NA,
    mcnemar_p = if (!is.null(mcnemar)) mcnemar$p.value else NA
  )
  status("%s: n_both=%d, agree=%d (%.1f%%), sens=%.1f%%, spec=%.1f%%", nm, n_both, tp+tn,
        (tp+tn)/n_both*100, sensitivity*100, specificity*100)
}

# any_readme
{
  cb <- side_by_side$cooper_any_readme; mb <- side_by_side$mc_any_readme
  both <- !is.na(cb) & !is.na(mb); n_both <- sum(both)
  cb2 <- cb[both]; mb2 <- mb[both]
  tp <- sum(cb2 & mb2); fn <- sum(cb2 & !mb2); fp <- sum(!cb2 & mb2); tn <- sum(!cb2 & !mb2)
  sensitivity <- tp / (tp + fn); specificity <- tn / (tn + fp)
  ppv <- tp / (tp + fp); npv <- tn / (tn + fn)
  n_disagree <- fn + fp
  pct_cooper_caught_mc_missed <- if (n_disagree > 0) fn / n_disagree * 100 else NA
  pct_mc_caught_cooper_missed <- if (n_disagree > 0) fp / n_disagree * 100 else NA
  mcnemar <- if ((fn + fp) > 0) tryCatch(mcnemar.test(matrix(c(tp, fn, fp, tn), nrow = 2), correct = TRUE), error = function(e) NULL) else NULL
  results[["any_readme"]] <- list(
    label = "Any README present (data or code, collapsed)",
    n_cooper_coded = sum(!is.na(cb)), n_mc_coded = sum(!is.na(mb)), n_both_coded = n_both,
    tp = tp, fn = fn, fp = fp, tn = tn,
    sensitivity = sensitivity, specificity = specificity, ppv = ppv, npv = npv,
    accuracy = (tp + tn) / n_both,
    n_agree = tp + tn, n_disagree = n_disagree, pct_agree = (tp + tn) / n_both * 100,
    pct_cooper_caught_mc_missed = pct_cooper_caught_mc_missed,
    pct_mc_caught_cooper_missed = pct_mc_caught_cooper_missed,
    mcnemar_stat = if (!is.null(mcnemar)) unname(mcnemar$statistic) else NA,
    mcnemar_df = if (!is.null(mcnemar)) unname(mcnemar$parameter) else NA,
    mcnemar_p = if (!is.null(mcnemar)) mcnemar$p.value else NA
  )
  status("any_readme: n_both=%d, agree=%d (%.1f%%), sens=%.1f%%, spec=%.1f%%",
        n_both, tp+tn, (tp+tn)/n_both*100, sensitivity*100, specificity*100)
}

# data_archive: overlap-based, not boolean.
{
  cv <- side_by_side$data_archive; mv <- side_by_side$mc_data_archive
  both <- !is.na(cv) & !is.na(mv) & nzchar(cv) & nzchar(mv)
  n_both <- sum(both)
  ov <- mapply(function(a, b) {
    sa <- trimws(strsplit(a, ";")[[1]]); sb <- trimws(strsplit(b, ";")[[1]])
    any(tolower(sa) %in% tolower(sb))
  }, cv[both], mv[both])
  results[["data_archive"]] <- list(
    label = "Archive platform (overlap match, not simple boolean)",
    n_cooper_coded = sum(!is.na(cv) & nzchar(cv %||% "")),
    n_mc_coded = sum(!is.na(mv) & nzchar(mv %||% "")),
    n_both_coded = n_both,
    n_agree = sum(ov), n_disagree = sum(!ov),
    pct_agree = mean(ov) * 100
  )
  status("data_archive: n_both=%d, agree=%d (%.1f%%)", n_both, sum(ov), mean(ov)*100)
}

# Qualitative verdict tallies from the worklist (disagreements only,
# empty until manual review fills them in).
verdict_cols_report <- c("data_availability", "data_archive", "data_license",
                         "data_download", "code_archived", "code_download", "any_readme")
verdict_tallies <- list()
for (nm in verdict_cols_report) {
  vcol <- paste0(nm, "_verdict")
  if (!vcol %in% names(review)) next
  tab <- table(review[[vcol]], useNA = "no")
  verdict_tallies[[nm]] <- tab
  if (length(tab) > 0) status("%s verdict tally: %s", nm, paste(names(tab), tab, sep = "=", collapse = ", "))
}

save(results, verdict_tallies, file = "data/comparison_statistics.RData")
status("Saved data/comparison_statistics.RData")
