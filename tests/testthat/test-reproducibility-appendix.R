# Appendix A.7's numbers are computed by the manuscript's own
# a7-reproducibility-load chunk from the saved reproducibility_check results
# (code/data/reproducibility_check_results.RData) and the per-paper detail
# (reproducibility_check_detail.RData). These tests count the same things
# independently from those files and compare.

repro_files <- function() {
  testthat::skip_if_not(file.exists(proj("code/data/reproducibility_check_results.RData")))
  e <- new.env()
  load(proj("code/data/reproducibility_check_results.RData"), envir = e)
  load(proj("code/data/reproducibility_check_detail.RData"), envir = e)
  e
}

a7 <- function() {
  skip_if_no_store()
  manuscript_env()
}

test_that("A.7's paper and script counts match the results file", {
  f <- repro_files(); m <- a7()
  tab <- f$out$results$table; st <- f$out$results$summary_table
  expect_equal(m$rp_n_papers, N_PAPERS)
  expect_equal(m$rp_n_cb, sum(st$repro_code_n > 0, na.rm = TRUE))
  expect_equal(m$rp_n_cb + m$rp_n_none + length(m$rp_na_ids), N_PAPERS)
  expect_equal(m$rp_n_scripts, nrow(tab))
  outcomes <- c("ran_ok", "errored", "skipped_missing_inputs", "dependency_unavailable", "not_parsed", "timed_out")
  # The outcome table lists every outcome that occurs.
  expect_true(all(unique(tab$outcome) %in% outcomes))
  expect_equal(sum(vapply(outcomes, m$rp_out, numeric(1))), nrow(tab))
  expect_equal(m$rp_n_all_ok + m$rp_n_none_ok + m$rp_n_mixed, length(unique(tab$paper_id[tab$paper_id %in% m$rp_code_bearing])))
  expect_equal(m$rp_n_ran_ok_papers, length(unique(tab$paper_id[tab$outcome == "ran_ok"])))
})

test_that("A.7's error types add up to the errored and timed-out scripts", {
  f <- repro_files(); m <- a7()
  expect_equal(m$rp_et("undefined_variable") + m$rp_et("runtime") + m$rp_et("timeout") +
                 m$rp_n_py_exception + m$rp_n_no_type, m$rp_n_err)
  expect_equal(m$rp_n_err, m$rp_out("errored") + m$rp_out("timed_out"))
})

test_that("A.7's install and matching numbers match the detail file", {
  f <- repro_files(); m <- a7()
  d <- f$reproducibility_detail
  expect_equal(m$rp_n_fz_papers, length(d$failed_and_zero_ok_papers))
  expect_equal(m$rp_n_fz_records, sum(d$pkg_counts_failed_and_zero_ok$n_papers_failed))
  expect_equal(m$rp_n_failed_papers, length(unique(d$per_paper_failed_deps$paper_id)))
  expect_lte(m$rp_n_fz_papers, m$rp_n_failed_papers)
  expect_lte(m$rp_n_spatial_records, m$rp_n_fz_records)
  expect_equal(length(m$rp_fz_list), nrow(d$pkg_counts_failed_and_zero_ok))
  expect_equal(m$rp_n_match_papers, nrow(d$by_paper_match))
  expect_equal(m$rp_n_match_rows, nrow(d$all_matches))
  expect_equal(m$rp_n_all_matched + m$rp_n_none_matched + m$rp_n_some_matched, m$rp_n_match_papers)
  expect_equal(m$rp_n_full + m$rp_n_partial, m$rp_n_matched)
  expect_equal(m$rp_n_matched + m$rp_n_unmatched, m$rp_n_match_rows)
})

test_that("the Python rerun is merged without losing any paper's earlier result", {
  f <- repro_files()
  st <- f$out$results$summary_table
  expect_equal(nrow(st), N_PAPERS)
  expect_false(anyDuplicated(st$paper_id) > 0)
  py <- attr(f$out, "python_rerun")$paper_ids
  testthat::skip_if(is.null(py), "Python rerun not merged yet")
  # Every merged Python paper has a real result.
  expect_false(anyNA(st$repro_code_n[st$paper_id %in% py]))
  expect_true(any(tolower(tools::file_ext(f$out$results$table$file_name)) %in% c("py", "ipynb")))
})

test_that("A.7 no longer types the numbers that are now computed", {
  txt <- manuscript_text()
  for (s in c("(4,394 rows, one row per script", "| 1,993 |", "only 85 of the 343 code-bearing papers",
              "133 papers had at least one statistical result", "naming 109 distinct packages",
              "from 138 to 154 papers", "256 of the 265 papers", "none of the 361 failed installs",
              "every single one came from executed R code"))
    expect_false(grepl(s, txt, fixed = TRUE), info = s)
})
