#!/usr/bin/env Rscript

# Rerun reproducibility_check() for every paper whose code_check result
# includes Python code (71 papers: 37 with Python only, 34 with Python and
# R). The full-corpus run used a metacheck version without Python support:
# Python-only papers got no reproducibility result at all, and mixed papers
# had only their R scripts run. Python support was added to
# reproducibility_check in metacheck dev d3b8594 (merged in c745eb1,
# 2026-10-07). Nothing else between the corpus version (80a7d37e) and that
# commit changes repo_check/data_check/code_check output: the other changes
# are the bibr 12.x import format (opt-in) and reference modules this
# corpus does not run, and the new Python write-call detection in
# code_file_refs() is only used by reproducibility_check
# (include_writes = TRUE).
#
# Same approach as rerun_infra_failures.R (a scattered list of papers,
# workers = 4, a separate output file), with three differences:
#   - paths follow this repository (code/data/bes.rds, cache on D:);
#   - skip_on_api_limit = FALSE: wait out a host rate limit rather than
#     silently skipping a file (the cause of the failed archive downloads
#     in the corpus run; see 01_run_metacheck/13_rerun_failed_archive_downloads.R);
#   - the paper list is computed from res_code_check rather than typed in.
#
# Output is a SEPARATE file (code/data/reproducibility_check_python_rerun.RData);
# merging these results into reproducibility_check_results.RData is a
# deliberate follow-up step, not done here.
#
# Installs scienceverse/metacheck@dev first ONLY if the installed version
# lacks Python support, so it can run alongside
# 13_rerun_failed_archive_downloads.R once dev is installed (first run:
# 2026-10-10, both scripts on dev c745eb17).
#
# Usage (from the repository root): Rscript code/data/reproducibility_check/rerun_python_papers.R

status <- function(...) {
  cat(sprintf("[%s] %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), sprintf(...)))
  utils::flush.console()
}

# -- Install dev only if Python support is missing ----------------------------
# Reinstalling unconditionally (as rerun_infra_failures.R does) would replace
# the package under any other R process using it, e.g. a concurrent
# 13_rerun_failed_archive_downloads.R run.
has_py <- requireNamespace("metacheck", quietly = TRUE) &&
  exists("repro_run_scripts_py", envir = asNamespace("metacheck"))
if (!has_py) {
  status("Installed metacheck lacks Python support; installing scienceverse/metacheck@dev from GitHub...")
  remotes::install_github("scienceverse/metacheck", ref = "dev", upgrade = "never", force = TRUE)
}
suppressPackageStartupMessages(library(metacheck))
sha <- utils::packageDescription("metacheck")[["RemoteSha"]]
status("metacheck %s (RemoteSha %s)", as.character(packageVersion("metacheck")), sha)
if (!exists("repro_run_scripts_py", envir = asNamespace("metacheck")))
  stop("Installed metacheck has no Python reproducibility support (repro_run_scripts_py not found).")

# Cache root: D:/ unless METACHECK_CACHE_ROOT says otherwise (see
# 13_rerun_failed_archive_downloads.R).
cache_root <- Sys.getenv("METACHECK_CACHE_ROOT", "D:/")
options(metacheck.cache.dir = cache_root)
if (cache_root == "D:/") stopifnot(dir.exists("D:/.metacheck_repo_cache"))
status("Cache root: %s", cache_root)

# -- Docker images ------------------------------------------------------------
for (img in c("ghcr.io/scienceverse/metacheck_r_large:latest",
              "ghcr.io/scienceverse/metacheck_py_small:latest")) {
  status("docker pull %s", img)
  rc <- system2("docker", c("pull", img))
  if (rc != 0) stop("docker pull failed for ", img, " -- is Docker Desktop running?")
}

# -- Which papers -------------------------------------------------------------
status("Finding papers with Python code in res_code_check...")
load("code/01_run_metacheck/res_code_check.RData")
ct <- res_code_check$table
lang <- tolower(ct$language)
py_ids <- sort(unique(ct$paper_id[lang %in% "python"]))
r_ids <- unique(ct$paper_id[lang %in% "r"])
rm(res_code_check, ct); invisible(gc())
data_dir <- "code/data"
results_dir <- file.path(data_dir, "batches", "python_rerun_results")
dir.create(results_dir, showWarnings = FALSE, recursive = TRUE)
write.csv(data.frame(paper_id = py_ids, also_r = py_ids %in% r_ids),
          file.path(data_dir, "reproducibility_check_python_rerun_ids.csv"), row.names = FALSE)
status("%d papers with Python code (%d also with R).", length(py_ids), sum(py_ids %in% r_ids))

bes <- readRDS("code/data/bes.rds")
stopifnot(all(py_ids %in% names(bes)))
# reproducibility_check() writes <paper_id>.rds to results_dir but does not
# skip papers already there, so a restarted run would redo finished papers.
# Skip them here (as run_reproducibility_check.R does); the final result is
# built from every saved file below, so they are still included.
done_ids <- sub("[.]rds$", "", list.files(results_dir, pattern = "[.]rds$"))
# A saved result without repro_code_n is a paper whose run ended in an error
# (2026-10-12: the disk ran full and Docker stopped for 16 papers); it is
# run again rather than counted as done.
has_result <- vapply(done_ids, function(id) {
  st <- tryCatch(readRDS(file.path(results_dir, paste0(id, ".rds")))$summary_table, error = function(e) NULL)
  !is.null(st) && "repro_code_n" %in% names(st) && !is.na(st$repro_code_n[1])
}, logical(1))
done_ids <- done_ids[has_result]
todo_ids <- setdiff(py_ids, done_ids)
status("%d of %d papers already saved in %s; %d to run.", length(intersect(py_ids, done_ids)),
       length(py_ids), results_dir, length(todo_ids))
target_papers <- bes[todo_ids]

# -- Run ----------------------------------------------------------------------
# results_dir: each paper's result is saved as it finishes, so a rerun of
# this script resumes instead of starting over.
warning_log <- file.path(data_dir, "reproducibility_check_python_rerun_warnings.log")
status("Running reproducibility_check on %d paper(s), up to 4 at a time...", length(target_papers))
# With workers > 1, reproducibility_check() runs each paper in its own
# callr::r_bg() process. options() do not reach those processes, so
# metacheck.cache.dir above is lost there and every cache falls back to the
# WORKING directory (.metacheck_cache_root() is
# getOption("metacheck.cache.dir", getwd())). On 2026-10-10 that put 4.5 GB
# of downloads into the repository folder instead of the cache root. The
# per-paper processes inherit the working directory, so switch it to the
# cache root for the duration of the call; every path passed in is made
# absolute first, and the original directory is restored afterwards.
repo_wd <- getwd()
results_dir_abs <- normalizePath(results_dir, winslash = "/", mustWork = TRUE)
warning_log_abs <- normalizePath(warning_log, winslash = "/", mustWork = FALSE)
if (length(todo_ids) > 0) {
  setwd(cache_root)
  status("Working directory for the paper processes: %s", getwd())
  tryCatch(withCallingHandlers(
    module_run(target_papers, "reproducibility_check",
               execute = TRUE, sandbox = "docker", install_missing = TRUE,
               timeout = 3000L, cache = TRUE, skip_on_api_limit = FALSE,
               workers = 4L, results_dir = results_dir_abs),
    warning = function(w) {
      cat(sprintf("[%s] %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), conditionMessage(w)),
          file = warning_log_abs, append = TRUE)
      invokeRestart("muffleWarning")
    }
  ), finally = setwd(repo_wd))
}
# Combine every saved per-paper result (this run's and any earlier
# interrupted run's) into one table/summary_table.
saved <- file.path(results_dir, paste0(py_ids, ".rds"))
status("%d of %d papers have a saved result.", sum(file.exists(saved)), length(py_ids))
# summary_table: capture_module_tables() stores the combined per-paper row
# at the top level of each file, so read it from there. table: read from
# each file's saved module directly, as run_reproducibility_check.R does;
# metacheck's collect_module_tables() does the same but is not exported.
saved <- saved[file.exists(saved)]
read_table <- function(f) {
  el <- readRDS(f)$modules[["reproducibility_check"]]$table
  if (is.null(el) || !is.data.frame(el) || nrow(el) == 0) NULL else el
}
res <- list(
  table = dplyr::bind_rows(lapply(saved, read_table)),
  summary_table = dplyr::bind_rows(lapply(saved, function(f) readRDS(f)$summary_table)))
attr(res, "metacheck_sha") <- sha

out_path <- file.path(data_dir, "reproducibility_check_python_rerun.RData")
save(res, file = out_path)
status("Saved %s (table %d rows, summary_table %d rows).", out_path, nrow(res$table), nrow(res$summary_table))
