# Rebuild the disagreement review worklist against the fresh (2026-09-14)
# corpus rerun -- Appendix A.5's seven fixes (Zenodo reliability,
# repository-platform coverage, rate-limit handling) applied to ALL 1861
# papers, not just the 989 that were previously disagreeing -- restricted
# to the same 7 columns 25_compute_comparison_statistics.R verdicts
# (data_availability, data_archive, data_license, data_download,
# code_archived, code_download, any_readme), same as
# 56_rebuild_worklist_carry_forward.R.
#
# Identical logic to 56_rebuild_worklist_carry_forward.R, with ONE change:
# the carry-forward source is code_data_preparation/_archive/
# disagreement_review_worklist_PRE_A5_2026-09-13.csv (the worklist as it
# stood immediately before this rerun, itself already the result of 56's
# own carry-forward plus every verdict resolved since 2026-09-05) rather
# than the older PRE_REDO_2026-09-05 archive 56 used -- carrying forward
# from the OLDER archive here would discard every verdict resolved in the
# 9 days between those two snapshots. For every one of the 7 columns,
# verdicts already recorded in that PRE_A5 archive are carried forward
# wherever the SPECIFIC disagreement is unchanged: same article_id, same
# Cooper raw value (fixed), same mc_* value. Only a genuinely NEW or
# CHANGED mc_* value (a real behavioural difference from A.5's fixes)
# needs fresh review.
#
# Usage: Rscript code_data_preparation/57_rebuild_worklist_carry_forward_post_a5.R

library(dplyr)
source("code_data_preparation/helpers.R")

load("data/cooper_vs_recreated.RData")   # side_by_side, fresh, 1861 rows

.cooper_bool <- function(x, positive, negative) {
  out <- rep(NA, length(x))
  out[x %in% positive] <- TRUE
  out[x %in% negative] <- FALSE
  out
}

# == The 5 boolean pairs (data_README/code_README/data_format/
#    code_language excluded, per 56's own header comment) ================
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

# data_archive: overlap-based, same as 04/05/56.
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

# any_readme: collapsed data_README OR code_README vs the one repo_check
# readme signal (09_add_any_readme_column.R's logic, folded in here).
data_readme_bool <- .cooper_bool(side_by_side$data_README, c("Yes", "Quasi-README"), "No")
code_readme_bool <- .cooper_bool(side_by_side$code_README, c("Yes", "Quasi-README"), "No")
side_by_side$cooper_any_readme <- ifelse(
  !is.na(data_readme_bool) & data_readme_bool, TRUE,
  ifelse(!is.na(code_readme_bool) & code_readme_bool, TRUE,
  ifelse(is.na(data_readme_bool) & is.na(code_readme_bool), NA, FALSE)))
side_by_side$mc_any_readme <- side_by_side$mc_data_README
ar_disagree <- !is.na(side_by_side$cooper_any_readme) & !is.na(side_by_side$mc_any_readme) &
  (side_by_side$cooper_any_readme != side_by_side$mc_any_readme)
flags[["any_readme"]] <- ar_disagree
ar_dir <- ifelse(ar_disagree, ifelse(side_by_side$cooper_any_readme, "cooper=Yes,mc=No", "cooper=No,mc=Yes"), NA)
for (i in which(ar_disagree)) {
  tag <- sprintf("any_readme[%s]", ar_dir[i])
  disagree_cols[i] <- if (nzchar(disagree_cols[i])) paste(disagree_cols[i], tag, sep = ";") else tag
}

status("Disagreement counts by column (of the 7 that get verdicted):")
for (nm in names(flags)) status("  %-20s %d", nm, sum(flags[[nm]], na.rm = TRUE))

has_disagreement <- nzchar(disagree_cols)
review <- side_by_side[has_disagreement, ]
review$disagreements <- disagree_cols[has_disagreement]
status("Fresh worklist: %d papers with >=1 disagreement among the 7 verdicted columns.", nrow(review))

# Distinct row id, same scheme as 06_restructure_review_columns.R/56.
dup <- duplicated(review$article_id) | duplicated(review$article_id, fromLast = TRUE)
review$row_id <- review$article_id
if (any(dup)) {
  ave_idx <- ave(seq_along(review$article_id), review$article_id, FUN = seq_along)
  review$row_id[dup] <- paste0(review$article_id[dup], "__dup", ave_idx[dup])
}
review <- review[, c("row_id", setdiff(names(review), "row_id"))]

verdict_cols <- c("data_availability", "data_archive", "data_license",
                  "data_download", "code_archived", "code_download", "any_readme")
for (col in verdict_cols) {
  review[[paste0(col, "_verdict")]] <- NA_character_
  review[[paste0(col, "_comment")]] <- NA_character_
}

# == Carry forward from the archived PRE-A.5 worklist ====================
old <- read.csv("code_data_preparation/_archive/disagreement_review_worklist_PRE_A5_2026-09-13.csv",
                stringsAsFactors = FALSE)

build_key <- function(article_id, cooper_val, mc_val)
  paste(article_id, as.character(cooper_val), as.character(mc_val), sep = "")

carried <- setNames(integer(length(verdict_cols)), verdict_cols)
needs_review <- setNames(integer(length(verdict_cols)), verdict_cols)

for (col in verdict_cols) {
  if (col == "data_archive") {
    cooper_col <- "data_archive"; mc_col <- "mc_data_archive"
  } else if (col == "any_readme") {
    cooper_col <- "cooper_any_readme"; mc_col <- "mc_any_readme"
  } else {
    p <- bool_pairs[[col]]; cooper_col <- p$cooper; mc_col <- p$mc
  }
  vcol <- paste0(col, "_verdict"); ccol <- paste0(col, "_comment")

  if (!all(c(cooper_col, mc_col, vcol, ccol) %in% names(old))) {
    status("  %-20s SKIPPED carry-forward: column not found in archived worklist", col)
    needs_review[col] <- sum(flags[[col]], na.rm = TRUE)
    next
  }

  old_verdict <- old[[vcol]]
  has_old_verdict <- !is.na(old_verdict) & nzchar(trimws(old_verdict))
  lut_key <- build_key(old$article_id, old[[cooper_col]], old[[mc_col]])[has_old_verdict]
  lut_verdict <- old_verdict[has_old_verdict]
  lut_comment <- old[[ccol]][has_old_verdict]
  first <- !duplicated(lut_key)  # keep first if an old key somehow repeats
  lut_key <- lut_key[first]; lut_verdict <- lut_verdict[first]; lut_comment <- lut_comment[first]

  col_flagged <- flags[[col]][has_disagreement]   # aligned with review's rows
  new_key <- build_key(review$article_id, review[[cooper_col]], review[[mc_col]])
  m <- match(new_key, lut_key)
  hit <- col_flagged & !is.na(m)

  review[[vcol]][hit] <- lut_verdict[m[hit]]
  review[[ccol]][hit] <- lut_comment[m[hit]]

  carried[col] <- sum(hit)
  needs_review[col] <- sum(col_flagged & !hit)
  status("  %-20s carried forward %d, needs fresh review %d", col, carried[col], needs_review[col])
}

status("TOTAL carried forward: %d, TOTAL needing fresh review: %d",
       sum(carried), sum(needs_review))

# A row is "reviewed" once every column flagged for it (among the 7) has
# a verdict -- same semantics as 06_restructure_review_columns.R/56.
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

write.csv(review, "data/disagreement_review_worklist.csv", row.names = FALSE)
status("Saved data/disagreement_review_worklist.csv: %d rows, %d fully reviewed (carried forward), %d needing fresh review.",
       nrow(review), sum(review$reviewed, na.rm = TRUE), sum(!review$reviewed, na.rm = TRUE))
