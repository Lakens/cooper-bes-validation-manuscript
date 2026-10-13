# Combining batch results and merging reruns into the corpus results
# (R/corpus_merge.R).

fake_result <- function(ids, files_per_paper = 2, report = "r") {
  list(
    module = "repo_check",
    table = data.frame(paper_id = rep(ids, each = files_per_paper),
                       file_name = sprintf("f%d", seq_len(length(ids) * files_per_paper))),
    summary_table = data.frame(paper_id = ids, files_n = rep(files_per_paper, length(ids))),
    report = report
  )
}

test_that("combining batches stacks tables and keeps every row once", {
  a <- fake_result(c("p1", "p2")); b <- fake_result("p3", files_per_paper = 3)
  out <- combine_batches(list(a, b))
  expect_equal(nrow(out$table), 4 + 3)
  expect_equal(out$summary_table$paper_id, c("p1", "p2", "p3"))
  expect_equal(out$module, "repo_check")
})

test_that("an empty batch does not break combining or add rows", {
  a <- fake_result(c("p1", "p2"))
  empty <- fake_result(character(0))
  empty$table <- data.frame(paper_id = character(0), file_name = character(0))
  out <- combine_batches(list(a, empty))
  expect_equal(nrow(out$table), 4)
  expect_equal(nrow(out$summary_table), 2)
})

test_that("non-table fields are kept per batch, and combining combined results does not nest them deeper", {
  a <- fake_result("p1", report = "A"); b <- fake_result("p2", report = "B"); c <- fake_result("p3", report = "C")
  ab <- combine_batches(list(a, b))
  expect_equal(ab$report_by_batch, list("A", "B"))
  abc <- combine_batches(list(ab, c))
  expect_false(any(grepl("_by_batch_by_batch", names(abc))))
  expect_equal(abc$report_by_batch, list("A", "B", "C"))
})

test_that("fields nested by the earlier combine function are flattened in order", {
  res <- list(summary_table = data.frame(paper_id = "p1"),
              report_by_batch = list("D"),
              report_by_batch_by_batch = list(list("A", "B"), list("C")))
  out <- normalize_batch_fields(res)
  expect_false(any(grepl("_by_batch_by_batch", names(out))))
  expect_setequal(unlist(out$report_by_batch), c("A", "B", "C", "D"))
  expect_length(out$report_by_batch, 4)
})

test_that("dropping papers removes all of their rows and nothing else", {
  res <- fake_result(c("p1", "p2", "p3"))
  out <- drop_ids(res, "p2")
  expect_false("p2" %in% out$table$paper_id)
  expect_false("p2" %in% out$summary_table$paper_id)
  expect_equal(nrow(out$table), 4)
  expect_equal(out$table$file_name, res$table$file_name[res$table$paper_id != "p2"])
  expect_equal(out$report, res$report)
})

test_that("merging a rerun replaces exactly the rerun papers' rows", {
  old <- fake_result(c("p1", "p2", "p3"))
  new <- fake_result("p2", files_per_paper = 5)
  new$table$file_name <- paste0("new", 1:5)
  out <- merge_rerun(old, new)
  expect_equal(nrow(out$summary_table), 3)
  expect_equal(sort(out$table$file_name[out$table$paper_id == "p2"]), sort(paste0("new", 1:5)))
  # Row names are not part of the data (they renumber when tables are stacked).
  keep <- function(t) { t <- t[t$paper_id != "p2", ]; rownames(t) <- NULL; t }
  expect_equal(keep(out$table), keep(old$table))
})

test_that("a merge that would lose or double a paper's summary row stops", {
  old <- fake_result(c("p1", "p2"))
  new <- fake_result("p9")  # not a paper of the corpus
  expect_error(merge_rerun(old, new))
})

test_that("removing the paper text keeps everything else", {
  res <- fake_result("p1")
  res$paper <- "full text"
  out <- strip_paper_text(res)
  expect_null(out$paper)
  expect_equal(out$table, res$table)
})
