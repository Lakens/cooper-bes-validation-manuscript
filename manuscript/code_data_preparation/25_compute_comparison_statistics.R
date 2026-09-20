# Computes the full empirical comparison statistics referenced by the
# manuscript's "Empirical Comparison" section: descriptives, 2x2
# confusion tables, sensitivity/specificity, McNemar's test, and the two
# asymmetric miss-rate percentages the user specifically asked for --
# "Cooper found X% of what metacheck missed" and "metacheck found Y% of
# what Cooper missed" -- for every column with a genuine boolean Cooper-
# vs-metacheck comparison in this validation project:
#   data_availability, data_archive (overlap-based, handled separately),
#   data_license, data_download, any_readme, code_archived, code_download
#
# Two data sources, used for different things:
#   - data/cooper_vs_recreated.RData (side_by_side, 1861 rows): the FULL
#     corpus, agreements included -- used for confusion tables, N's,
#     sensitivity/specificity, McNemar's test.
#   - data/disagreement_review_worklist.csv (718 rows, disagreements
#     only, each with an individually-verified _verdict/_comment):
#     used for the qualitative COOPER_RIGHT/METACHECK_RIGHT/etc. verdict
#     tallies, which only exist for genuine disagreements.
#
# Usage: Rscript 25_compute_comparison_statistics.R

status <- function(...) cat(sprintf("[%s] %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), sprintf(...)))
`%||%` <- function(a, b) if (is.null(a)) b else a
library(dplyr)

load("data/cooper_vs_recreated.RData")   # side_by_side, 1861 rows
review <- read.csv("data/disagreement_review_worklist.csv", stringsAsFactors = FALSE)  # 718 rows

.cooper_bool <- function(x, positive, negative) {
  out <- rep(NA, length(x))
  out[x %in% positive] <- TRUE
  out[x %in% negative] <- FALSE
  out
}

bool_pairs <- list(
  data_availability = list(cooper = "data_availability", mc = "mc_data_availability",
                           positive = "Yes", negative = c("No", "No, but they are available on request"),
                           label = "Data availability"),
  data_license      = list(cooper = "data_license", mc = "mc_data_license",
                           positive = "Yes", negative = "No",
                           label = "Data licence present"),
  data_download     = list(cooper = "data_download", mc = "mc_data_download",
                           positive = c("Yes", "Yes, but not all data"), negative = "No",
                           label = "Data downloadable and usable"),
  code_archived     = list(cooper = "code_archived", mc = "mc_code_archived",
                           positive = "Yes", negative = "No",
                           label = "Code archived"),
  code_download     = list(cooper = "code_download", mc = "mc_code_download",
                           positive = "Yes", negative = "No",
                           label = "Code downloadable")
)

# any_readme lives only in the worklist (built by 09_add_any_readme_column.R
# from the full corpus, but not re-saved as its own full-corpus RData
# object) -- reconstruct its full-corpus version the same way that script
# did, directly from side_by_side's data_README/code_README +
# mc_data_README, so the full N (agreements included) is available here too.
data_readme_bool <- .cooper_bool(side_by_side$data_README, c("Yes", "Quasi-README"), "No")
code_readme_bool <- .cooper_bool(side_by_side$code_README, c("Yes", "Quasi-README"), "No")
side_by_side$cooper_any_readme <- ifelse(
  !is.na(data_readme_bool) & data_readme_bool, TRUE,
  ifelse(!is.na(code_readme_bool) & code_readme_bool, TRUE,
  ifelse(is.na(data_readme_bool) & is.na(code_readme_bool), NA, FALSE)))
side_by_side$mc_any_readme <- side_by_side$mc_data_README

results <- list()

for (nm in names(bool_pairs)) {
  p <- bool_pairs[[nm]]
  cb <- .cooper_bool(side_by_side[[p$cooper]], p$positive, p$negative)
  mb <- side_by_side[[p$mc]]

  both <- !is.na(cb) & !is.na(mb)
  n_both <- sum(both)
  cb2 <- cb[both]; mb2 <- mb[both]

  tp <- sum(cb2 & mb2)     # Cooper Yes, metacheck Yes
  fn <- sum(cb2 & !mb2)    # Cooper Yes, metacheck No  (metacheck MISSED what Cooper found)
  fp <- sum(!cb2 & mb2)    # Cooper No,  metacheck Yes (metacheck found what Cooper MISSED)
  tn <- sum(!cb2 & !mb2)   # Cooper No,  metacheck No

  sensitivity <- tp / (tp + fn)   # of what Cooper called Yes, % metacheck also called Yes
  specificity <- tn / (tn + fp)   # of what Cooper called No, % metacheck also called No
  ppv <- tp / (tp + fp)           # of what metacheck called Yes, % Cooper agreed
  npv <- tn / (tn + fn)           # of what metacheck called No, % Cooper agreed
  accuracy <- (tp + tn) / n_both

  # The two asymmetric rates the user specifically asked for:
  # "Cooper got what metacheck missed X% of the time" -- among all cases
  # where the two disagree (fn + fp), what fraction are cases where
  # Cooper said Yes and metacheck said No (metacheck's misses)?
  n_disagree <- fn + fp
  pct_cooper_caught_mc_missed <- if (n_disagree > 0) fn / n_disagree * 100 else NA
  pct_mc_caught_cooper_missed <- if (n_disagree > 0) fp / n_disagree * 100 else NA

  mcnemar <- if ((fn + fp) > 0) {
    tryCatch(mcnemar.test(matrix(c(tp, fn, fp, tn), nrow = 2), correct = TRUE),
             error = function(e) NULL)
  } else NULL

  results[[nm]] <- list(
    label = p$label,
    n_cooper_coded = sum(!is.na(cb)),
    n_mc_coded = sum(!is.na(mb)),
    n_both_coded = n_both,
    tp = tp, fn = fn, fp = fp, tn = tn,
    sensitivity = sensitivity, specificity = specificity,
    ppv = ppv, npv = npv, accuracy = accuracy,
    n_agree = tp + tn, n_disagree = n_disagree,
    pct_agree = (tp + tn) / n_both * 100,
    pct_cooper_caught_mc_missed = pct_cooper_caught_mc_missed,
    pct_mc_caught_cooper_missed = pct_mc_caught_cooper_missed,
    mcnemar_stat = if (!is.null(mcnemar)) unname(mcnemar$statistic) else NA,
    mcnemar_df = if (!is.null(mcnemar)) unname(mcnemar$parameter) else NA,
    mcnemar_p = if (!is.null(mcnemar)) mcnemar$p.value else NA
  )
  status("%s: n_both=%d, agree=%d (%.1f%%), sens=%.1f%%, spec=%.1f%%, McNemar p=%s",
         nm, n_both, tp+tn, (tp+tn)/n_both*100, sensitivity*100, specificity*100,
         if (!is.null(mcnemar)) format.pval(mcnemar$p.value, digits = 3) else "NA")
}

# any_readme (built above, not in bool_pairs since its columns are named
# differently -- cooper_any_readme/mc_any_readme, not a cooper/mc pair
# from a single Cooper column)
{
  cb <- side_by_side$cooper_any_readme
  mb <- side_by_side$mc_any_readme
  both <- !is.na(cb) & !is.na(mb)
  n_both <- sum(both)
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

# data_archive: overlap-based (not boolean), so sensitivity/specificity
# don't apply the same way -- report agreement rate and the disagreement
# breakdown instead.
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
# each individually reviewed and resolved earlier this session).
verdict_cols <- c("data_availability", "data_archive", "data_license",
                  "data_download", "code_archived", "code_download")
verdict_tallies <- list()
for (nm in verdict_cols) {
  vcol <- paste0(nm, "_verdict")
  if (!vcol %in% names(review)) next
  tab <- table(review[[vcol]], useNA = "no")
  verdict_tallies[[nm]] <- tab
  status("%s verdict tally: %s", nm, paste(names(tab), tab, sep = "=", collapse = ", "))
}
# any_readme's verdict column is separately named
if ("any_readme_verdict" %in% names(review)) {
  tab <- table(review$any_readme_verdict, useNA = "no")
  verdict_tallies[["any_readme"]] <- tab
  status("any_readme verdict tally: %s", paste(names(tab), tab, sep = "=", collapse = ", "))
}

save(results, verdict_tallies, file = "data/comparison_statistics.RData")
status("Saved data/comparison_statistics.RData")
