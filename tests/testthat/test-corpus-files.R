# Saving the corpus results in parts and reading them back (R/corpus_files.R).

test_that("a result saved in parts reads back identical", {
  dir <- tempfile(); dir.create(dir)
  path <- file.path(dir, "res_data_check.RData")
  obj <- list(table = data.frame(paper_id = c("p1", "p2"), x = 1:2),
              previews = setNames(lapply(1:50, function(i) data.frame(v = runif(200))), paste0("f", 1:50)))
  # A tiny memory target forces several parts.
  save_corpus_result(obj, "res_data_check", path, target_part_mem = 20000)
  parts <- list.files(dir, pattern = "[.]part[0-9]+[.]RData$")
  expect_gt(length(parts), 1)
  # The main file holds the tables without the large list, under the usual name.
  e <- new.env(); load(path, envir = e)
  expect_null(e$res_data_check$previews)
  expect_equal(e$res_data_check$table, obj$table)
  expect_identical(read_corpus_result(path), obj)
})

test_that("saving with fewer parts removes the left-over part files", {
  dir <- tempfile(); dir.create(dir)
  path <- file.path(dir, "res_code_check.RData")
  obj <- list(table = data.frame(paper_id = "p1"),
              prev_outputs_by_batch = lapply(1:20, function(i) runif(500)))
  save_corpus_result(obj, "res_code_check", path, target_part_mem = 5000)
  n_many <- length(list.files(dir, pattern = "[.]part"))
  save_corpus_result(obj, "res_code_check", path, target_part_mem = 1e9)
  expect_gt(n_many, 1)
  expect_equal(length(list.files(dir, pattern = "[.]part")), 1)
  expect_identical(read_corpus_result(path), obj)
})

test_that("a result without a large list is saved as one file, as before", {
  dir <- tempfile(); dir.create(dir)
  path <- file.path(dir, "res_repo_check.RData")
  obj <- list(table = data.frame(paper_id = "p1"))
  save_corpus_result(obj, "res_repo_check", path)
  expect_equal(list.files(dir), "res_repo_check.RData")
  expect_identical(read_corpus_result(path), obj)
})

test_that("every corpus result file in the repository is under GitHub's 2 GB limit, and its parts are complete", {
  files <- list.files(proj("code/01_run_metacheck"), pattern = "^res_.*[.]RData$", full.names = TRUE)
  expect_true(all(file.size(files) < 2e9), info = paste(basename(files[file.size(files) >= 2e9]), collapse = ", "))
  for (name in names(corpus_split_fields)) {
    path <- proj("code/01_run_metacheck", paste0(name, ".RData"))
    e <- new.env(); load(path, envir = e)
    parts <- attr(e[[name]], "corpus_parts")
    expect_false(is.null(parts), info = name)
    expect_true(all(file.exists(file.path(dirname(path), parts$files))), info = name)
  }
})
