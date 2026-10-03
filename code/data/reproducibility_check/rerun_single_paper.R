#!/usr/bin/env Rscript

# Rerun ONE specific paper alone (workers = 1, no Docker concurrency), for a
# paper that crashed with the same "callr subprocess failed: could not start
# R, exited with non-zero status, has crashed or was killed" error on TWO
# separate attempts under workers > 1 -- to see whether the crash is
# resource-contention-sensitive (goes away with no concurrent workers) or a
# genuine, repeatable problem with this paper's own code/environment.

suppressPackageStartupMessages(library(metacheck))

TARGET_PAPER_ID <- "10_1111_2041_210x_13384"

infer_repo_root <- function() {
  args_vec <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args_vec, value = TRUE)
  if (length(file_arg) > 0L) {
    script_path <- sub("^--file=", "", file_arg[1L])
    if (nzchar(script_path)) {
      script_dir <- normalizePath(dirname(script_path), winslash = "/", mustWork = FALSE)
      return(dirname(script_dir))
    }
  }
  dirname(getwd())
}

locate_bes <- function(repo_root) {
  candidates <- c(file.path(repo_root, "bes.rds"), file.path(repo_root, "manuscript", "data", "bes.rds"))
  hit <- candidates[file.exists(candidates)]
  if (length(hit) == 0L) stop("Could not find bes.rds.")
  hit[1L]
}

status <- function(...) {
  cat(sprintf("[%s] %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), sprintf(...)))
  utils::flush.console()
}

if ("package:metacheck" %in% search()) detach("package:metacheck", unload = TRUE, character.only = TRUE)
message("Installing scienceverse/metacheck@dev from GitHub...")
remotes::install_github("scienceverse/metacheck", ref = "dev", upgrade = "never", force = TRUE)
suppressPackageStartupMessages(library(metacheck))
cat("metacheck version: ", as.character(packageVersion("metacheck")), "\n", sep = "")

repo_root <- infer_repo_root()
options(metacheck.cache.dir = repo_root)

bes_path <- locate_bes(repo_root)
cat("Loading corpus from: ", bes_path, "\n", sep = "")
bes <- readRDS(bes_path)

ids <- vapply(seq_along(bes), function(i) tryCatch(paper_id(bes[i]), error = function(e) NA_character_), character(1))
idx <- match(TARGET_PAPER_ID, ids)
if (is.na(idx)) stop("Could not find in corpus: ", TARGET_PAPER_ID)
status("Found target paper at corpus index %d.", idx)

# No workers/results_dir here: single paper, ordinary sequential call, same
# as the rest of the corpus originally ran under before workers was added --
# the simplest, least-confounded way to see if the crash is contention-related.
status("Running reproducibility_check alone (no concurrency)...")
res <- module_run(bes[idx], "reproducibility_check",
                  execute = TRUE, sandbox = "docker", install_missing = TRUE,
                  timeout = 3000L, cache = TRUE, skip_on_api_limit = TRUE)

out_path <- file.path(repo_root, "data", "reproducibility_check_13384_solo_rerun.RData")
save(res, file = out_path)
cat("Saved solo rerun output to: ", out_path, "\n", sep = "")
cat("table rows: ", nrow(res$table), "\n", sep = "")
cat("summary_table rows: ", nrow(res$summary_table), "\n", sep = "")
cat("traffic_light: ", res$traffic_light %||% "NA", "\n", sep = "")
cat("Finished.\n")
