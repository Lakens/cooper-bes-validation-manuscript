# Applies the 87 verdicts from the manual/LLM-assisted review of the 57
# disagreements Appendix A.5's fixes left newly-surfaced or changed
# (data/disagreement_review_worklist.csv rows where reviewed != TRUE after
# 57_rebuild_worklist_carry_forward_post_a5.R's carry-forward). Each row's
# evidence (repo_check/data_check/code_check saved output, the paper's own
# extracted availability-statement text) was checked directly; see
# verdicts_57.csv (also archived alongside this script) for the full,
# per-row reasoning.
#
# Usage: Rscript code_data_preparation/59_apply_a5_review_verdicts.R

source("code_data_preparation/helpers.R")

review <- read.csv("data/disagreement_review_worklist.csv", stringsAsFactors = FALSE)
verdicts <- read.csv("code_data_preparation/verdicts_a5_review.csv", stringsAsFactors = FALSE)

status("Applying %d verdicts across %d papers.", nrow(verdicts), length(unique(verdicts$article_id)))

n_applied <- 0
for (i in seq_len(nrow(verdicts))) {
  aid <- verdicts$article_id[i]
  construct <- verdicts$construct[i]
  vcol <- paste0(construct, "_verdict")
  ccol <- paste0(construct, "_comment")
  if (!all(c(vcol, ccol) %in% names(review))) {
    status("WARNING: no %s/%s columns for construct '%s' (row %d, %s) -- skipped.",
           vcol, ccol, construct, i, aid)
    next
  }
  row_idx <- which(review$article_id == aid)
  if (length(row_idx) == 0) {
    status("WARNING: article_id '%s' not found in worklist -- skipped.", aid)
    next
  }
  review[[vcol]][row_idx] <- verdicts$verdict[i]
  review[[ccol]][row_idx] <- verdicts$comment[i]
  n_applied <- n_applied + 1
}
status("Applied %d of %d verdicts.", n_applied, nrow(verdicts))

# Recompute `reviewed`: TRUE once every column flagged for a row (in its
# own `disagreements` text) has a non-empty verdict. Same semantics as
# 56_rebuild_worklist_carry_forward.R/57's own reviewed computation, but
# using grepl() directly against the full construct name (not a naive
# strsplit on ";", which mis-splits when an mc_ value itself contains a
# semicolon -- e.g. mc=GitHub, GitLab, Codeberg or similar platform;Zenodo
# for a multi-platform data_archive answer -- confirmed live while cross-
# checking this script's own verdict coverage).
verdict_cols <- c("data_availability", "data_archive", "data_license",
                  "data_download", "code_archived", "code_download", "any_readme")
flagged_cols_for_row <- function(disagreements_text) {
  if (is.na(disagreements_text) || !nzchar(disagreements_text)) return(character(0))
  by_len <- verdict_cols[order(-nchar(verdict_cols))]
  by_len[vapply(by_len, function(col) {
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
status("Saved data/disagreement_review_worklist.csv: %d rows, %d fully reviewed, %d still needing review.",
       nrow(review), sum(review$reviewed, na.rm = TRUE), sum(!review$reviewed, na.rm = TRUE))
