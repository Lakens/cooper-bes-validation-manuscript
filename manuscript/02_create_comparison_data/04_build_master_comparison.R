# Create master_comparison.rds

# This script does NOT independently re-derive mc_data_availability/
# mc_data_archive/mc_data_license/mc_data_download/mc_code_archived/
# mc_code_download/mc_code_language from raw repo_check/data_check/
# code_check output. Those columns already exist in this folder's own
# 01_recreate_cooper_columns.R output (cooper_vs_recreated.rds, read
# directly below), which derives them straight from
# 01_run_metacheck/res_*.RData. This script only adds what
# cooper_vs_recreated.rds does NOT already have:
#   - mc_data_open / mc_code_open      (from open_practices' summary_table)
#   - oddpub_data_open / oddpub_code_open (from ODDPub's summary_table)
#   - the accuracy_summary metrics themselves (sensitivity/specificity/
#     accuracy of open_practices and ODDPub against Cooper's own
#     data_open/code_open ground truth)
#   - recorder_ID (which hackathon participant coded each paper) -- kept
#     on the DOI-corrected, one-row-per-paper cooper join below (not on
#     side_by_side, which never carried it), so manuscript.qmd can read
#     the true 1861-paper recorder_ID distribution from here instead of
#     loading Cooper's raw CSV directly (that raw CSV still has the 4
#     duplicate-DOI rows described above, uncorrected, so a median/min/max
#     computed straight from it silently spans 1865 rows, not 1861).
#
# Usage (from inside manuscript/): Rscript 02_create_comparison_data/04_build_master_comparison.R
library(dplyr)

status <- function(...) {
  cat(sprintf("[%s] %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), sprintf(...)))
  utils::flush.console()
}

# == Load side_by_side (the already-correct mc_* columns) ===========================

# Read directly from final_pipeline's own canonical output location
# (manuscript/data/) rather than a folder-local copy -- master_comparison
# is a strict superset of side_by_side's 25 columns (this script only
# ADDS mc_data_open/mc_code_open/oddpub_*/recorder_ID to it, never
# redefines any existing column), so keeping a second copy of
# cooper_vs_recreated.rds here would just be one more file to keep in
# sync with no benefit -- every downstream consumer of the columns
# side_by_side has can and should read master_comparison.rds instead
# (see 03_comparing_results/01_compute_comparison_statistics.R). Saved
# and read as .rds, not .RData -- side_by_side is a single plain
# dataframe (see final_pipeline/02_build_comparison_data.R's own save()).
status("Loading data/cooper_vs_recreated.rds (side_by_side)...")
side_by_side <- readRDS("data/cooper_vs_recreated.rds")  # 1861 rows, one per paper (article_id)

# == Load open_practices / ODDPub summary tables =====================================

status("Loading 01_run_metacheck/res_open_practices.RData and res_oddpub.RData...")
load("01_run_metacheck/res_open_practices.RData")  # -> res_open_practices
load("01_run_metacheck/res_oddpub.RData")          # -> res_oddpub

mc_q1 <- res_open_practices$summary_table |>
  select(paper_id, mc_data_open = data_open, mc_code_open = code_open,
         mc_on_request = on_request)

oddpub_q1 <- res_oddpub$summary_table |>
  select(paper_id, oddpub_data_open = data_open, oddpub_code_open = code_open)

# == Join onto side_by_side ===========================================================

master_comparison <- side_by_side |>
  left_join(mc_q1,     by = c("article_id" = "paper_id")) |>
  left_join(oddpub_q1, by = c("article_id" = "paper_id"))

status("master_comparison built: %d papers, %d columns.",
       nrow(master_comparison), ncol(master_comparison))

# == OddPub vs metacheck's own open_practices module: accuracy against Cooper's coders ====
# Ground truth is Cooper's own data_open/code_open column (not
# data_availability/code_archived, which side_by_side already scores
# elsewhere): "Yes"/"Yes, but not all files" -> TRUE, "No" -> FALSE,
# anything else (an ambiguous label, or NA) excluded from this specific
# comparison, matching the original script's own logic exactly (this
# part IS reused as-is, since it isn't duplicated anywhere else in the
# repo).

.cooper_yesno_data <- function(x) {
  dplyr::case_when(
    x %in% c("Yes", "Yes, but not all files") ~ TRUE,
    x == "No" ~ FALSE,
    TRUE ~ NA
  )
}
.cooper_yesno_code <- function(x) {
  dplyr::case_when(
    x == "Yes" ~ TRUE,
    x == "No" ~ FALSE,
    TRUE ~ NA
  )
}

.accuracy_metrics <- function(pred, truth) {
  valid <- !is.na(pred) & !is.na(truth)
  pred <- pred[valid]
  truth <- truth[valid]
  tab <- table(pred = factor(pred, c(FALSE, TRUE)), truth = factor(truth, c(FALSE, TRUE)))
  n_pos <- sum(truth)
  n_neg <- sum(!truth)
  list(
    n = sum(valid),
    n_positive = n_pos,
    n_negative = n_neg,
    sensitivity = if (n_pos > 0) tab["TRUE", "TRUE"] / n_pos else NA_real_,
    specificity = if (n_neg > 0) tab["FALSE", "FALSE"] / n_neg else NA_real_,
    accuracy = sum(diag(tab)) / sum(tab)
  )
}

# Cooper's data_open/code_open columns live on the raw CSV, not on
# side_by_side (which only carries data_availability/code_archived etc.)
# -- load them fresh, joined the same way as the rest of this pipeline.
status("Loading Cooper et al.'s coded ground truth for data_open/code_open...")
cooper <- read.csv(
  "02_create_comparison_data/BES-data-code-hackathon-cleaned_2025-12-01.csv",
  na.strings = "NA", stringsAsFactors = FALSE
)
.fix_invalid_utf8 <- function(df) {
  fix_col <- function(x) {
    if (!is.character(x)) return(x)
    bad <- !validEnc(x)
    if (any(bad)) x[bad] <- iconv(x[bad], from = "UTF-8", to = "UTF-8", sub = "byte")
    x
  }
  df[] <- lapply(df, fix_col)
  df
}
cooper <- .fix_invalid_utf8(cooper)

# Cooper et al.'s coded CSV has 4 DOIs each mistakenly copy-pasted onto TWO
# different papers (confirmed in build.R, cooper_validation_metacheck repo,
# by cross-referencing paper_number -- unique, never duplicated -- against
# the master 8112-row metadata list: for all 8 affected rows the coder's
# own recorded journal matches that paper_number's TRUE journal, so only
# the doi field was wrong on one row of each pair, not two independent
# codings of the same paper). Uncorrected, both rows of each pair map to
# the SAME article_id via sample.csv's doi-keyed lookup below, producing a
# many-to-many join and duplicate rows in master_comparison (confirmed
# live: 1861 -> 1869 rows before this fix). sample.csv itself already
# reflects the corrected DOIs (built by build.R's own phase0_fetch(),
# which applies this same correction before deduplicating) -- this must
# be applied here too, to the FRESH copy of cooper loaded above, so this
# script's join uses the same corrected DOIs sample.csv was keyed on.
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

master_comparison <- master_comparison |>
  left_join(cooper |> select(article_id, data_open, code_open, recorder_ID), by = "article_id")

data_truth <- .cooper_yesno_data(master_comparison$data_open)
code_truth <- .cooper_yesno_code(master_comparison$code_open)

accuracy_summary <- list(
  metacheck_data = .accuracy_metrics(master_comparison$mc_data_open, data_truth),
  metacheck_code = .accuracy_metrics(master_comparison$mc_code_open, code_truth),
  oddpub_data    = .accuracy_metrics(master_comparison$oddpub_data_open, data_truth),
  oddpub_code    = .accuracy_metrics(master_comparison$oddpub_code_open, code_truth)
)

cat("\n=== OddPub vs metacheck open_practices: accuracy against Cooper's human coders ===\n")
for (nm in names(accuracy_summary)) {
  m <- accuracy_summary[[nm]]
  cat(sprintf("%-16s n=%4d (pos=%d, neg=%d)  sensitivity=%.3f  specificity=%.3f  accuracy=%.3f\n",
              nm, m$n, m$n_positive, m$n_negative, m$sensitivity, m$specificity, m$accuracy))
}

attr(master_comparison, "accuracy_summary") <- accuracy_summary

# Saved as .rds, not .RData: master_comparison is a single dataframe (the
# accuracy_summary attribute travels with it either way), so .rds --
# readRDS() into any variable name, rather than load()'s fixed
# object-name behaviour -- is the right format for a single object.
saveRDS(master_comparison, file = "02_create_comparison_data/master_comparison.rds")
status("Saved 02_create_comparison_data/master_comparison.rds: %d papers, %d columns.",
       nrow(master_comparison), ncol(master_comparison))
