# Adds what cooper_vs_metacheck does NOT already have:
#   - mc_data_open / mc_code_open      (from open_practices' summary_table)
#   - oddpub_data_open / oddpub_code_open (from ODDPub's summary_table)
#   - the accuracy_summary metrics themselves (sensitivity/specificity/
#     accuracy of open_practices and ODDPub against Cooper's own
#     data_open/code_open ground truth)
#   - recorder_ID (which hackathon participant coded each paper)
#
# Converted from code/02_create_comparison_data/03_build_master_comparison.R.
# cooper_vs_metacheck already has the mc_data_availability/mc_data_archive/
# mc_data_license/mc_data_download/mc_code_archived/mc_code_download/
# mc_code_language columns -- this does not re-derive them.

build_master_comparison <- function(cooper_vs_metacheck, res_open_practices_file,
                                     res_oddpub_file, cooper_csv_file, sample_csv_file) {
  side_by_side <- cooper_vs_metacheck

  load(res_open_practices_file)  # -> res_open_practices
  load(res_oddpub_file)          # -> res_oddpub

  mc_q1 <- res_open_practices$summary_table |>
    dplyr::select(paper_id, mc_data_open = data_open, mc_code_open = code_open,
           mc_on_request = on_request)

  oddpub_q1 <- res_oddpub$summary_table |>
    dplyr::select(paper_id, oddpub_data_open = data_open, oddpub_code_open = code_open)

  master_comparison <- side_by_side |>
    dplyr::left_join(mc_q1,     by = c("article_id" = "paper_id")) |>
    dplyr::left_join(oddpub_q1, by = c("article_id" = "paper_id"))

  # OddPub vs metacheck's own open_practices module: accuracy against
  # Cooper's human coders. Ground truth is Cooper's own data_open/code_open
  # column (not data_availability/code_archived, which side_by_side already
  # scores elsewhere): "Yes"/"Yes, but not all files" -> TRUE, "No" ->
  # FALSE, anything else (an ambiguous label, or NA) excluded.
  cooper_yesno_data <- function(x) {
    dplyr::case_when(
      x %in% c("Yes", "Yes, but not all files") ~ TRUE,
      x == "No" ~ FALSE,
      TRUE ~ NA
    )
  }
  cooper_yesno_code <- function(x) {
    dplyr::case_when(
      x == "Yes" ~ TRUE,
      x == "No" ~ FALSE,
      TRUE ~ NA
    )
  }

  accuracy_metrics <- function(pred, truth) {
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
  # side_by_side -- load them fresh, joined the same way as the rest of
  # this pipeline (same DOI-duplicate correction as recreate_cooper_columns'
  # build_cooper_vs_metacheck(), applied independently here since this
  # reads the raw CSV fresh rather than reusing that target's corrected copy).
  cooper <- read.csv(cooper_csv_file, na.strings = "NA", stringsAsFactors = FALSE)
  cooper <- .fix_invalid_utf8(cooper)

  doi_corrections <- data.frame(
    paper_number = c("57", "1275", "47", "7176"),
    correct_doi  = c("10.1002/2688-8319.12136", "10.1111/1365-2656.13512",
                     "10.1111/1365-2656.13145", "10.1111/1365-2435.12981"),
    stringsAsFactors = FALSE
  )
  m <- match(as.character(cooper$paper_number), doi_corrections$paper_number)
  fix <- !is.na(m)
  if (any(fix)) cooper$doi[fix] <- doi_corrections$correct_doi[m[fix]]

  sampled <- read.csv(sample_csv_file, colClasses = "character")
  doi_to_article_id <- setNames(sampled$article_id, tolower(sampled$doi))
  cooper$article_id <- doi_to_article_id[tolower(cooper$doi)]

  master_comparison <- master_comparison |>
    dplyr::left_join(cooper |> dplyr::select(article_id, data_open, code_open, recorder_ID), by = "article_id")

  data_truth <- cooper_yesno_data(master_comparison$data_open)
  code_truth <- cooper_yesno_code(master_comparison$code_open)

  accuracy_summary <- list(
    metacheck_data = accuracy_metrics(master_comparison$mc_data_open, data_truth),
    metacheck_code = accuracy_metrics(master_comparison$mc_code_open, code_truth),
    oddpub_data    = accuracy_metrics(master_comparison$oddpub_data_open, data_truth),
    oddpub_code    = accuracy_metrics(master_comparison$oddpub_code_open, code_truth)
  )

  cat("\n=== OddPub vs metacheck open_practices: accuracy against Cooper's human coders ===\n")
  for (nm in names(accuracy_summary)) {
    mm <- accuracy_summary[[nm]]
    cat(sprintf("%-16s n=%4d (pos=%d, neg=%d)  sensitivity=%.3f  specificity=%.3f  accuracy=%.3f\n",
                nm, mm$n, mm$n_positive, mm$n_negative, mm$sensitivity, mm$specificity, mm$accuracy))
  }

  attr(master_comparison, "accuracy_summary") <- accuracy_summary
  master_comparison
}
