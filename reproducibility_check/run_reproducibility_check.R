#!/usr/bin/env Rscript

# Prepare the corpus for a metacheck reproducibility check. Always installs
# scienceverse/metacheck@dev fresh from GitHub before running (never a
# vendored/local copy) -- see ensure_repro_branch(). If that installed
# package ever lacks a dedicated `reproducibility_check` module, we
# gracefully fall back to the same repo/data/code chain used by the
# project's batch pipeline.
#
# Usage:
#   Rscript run_reproducibility_check.R --max-papers 10
#   Rscript run_reproducibility_check.R
#   Rscript run_reproducibility_check.R --batch-size 25
#   Rscript run_reproducibility_check.R --no-resume
#
# The script is intentionally conservative: it will reuse the local repo
# cache and only fetch missing repository files, making it suitable for a
# different computer that has the same OneDrive-synced file set.
#
# BATCHING / CHECKPOINTING: the corpus is processed BATCH_SIZE papers at a
# time (default 50), and each batch's result is saved to data/batches/ as
# soon as it finishes -- mirroring the pattern already proven in
# manuscript/code_data_preparation/01_run_checks.R for this same corpus.
# This means:
#   - killing the run (Ctrl+C, a crash, a machine reboot) and re-running
#     later resumes at the first unfinished batch instead of starting over;
#   - a single batch that errors out (a bad repo, a network failure) is
#     logged and skipped rather than aborting the entire run -- rerun the
#     script later to retry just the missing batches;
#   - the final combined result (data/reproducibility_check_results.RData)
#     is only as complete as the batches that have finished; the script
#     reports how many that is every run.
# Pass --no-resume to recompute every batch from scratch (existing batch
# files are still overwritten, not deleted first).

suppressPackageStartupMessages(library(metacheck))
suppressPackageStartupMessages(library(dplyr))

parse_args <- function(args) {
  opts <- list(max_papers = NULL, batch_size = 50L, resume = TRUE,
              execute = TRUE, timeout = 3000L, workers = 1L)
  i <- 1L
  while (i <= length(args)) {
    a <- args[i]
    if (a %in% c("--max-papers", "-n", "--n")) {
      if (i == length(args)) stop("Missing value for ", a)
      opts$max_papers <- as.integer(args[i + 1L])
      if (is.na(opts$max_papers) || opts$max_papers < 1L) {
        stop("--max-papers must be a positive integer.")
      }
      i <- i + 2L
    } else if (a == "--batch-size") {
      if (i == length(args)) stop("Missing value for ", a)
      opts$batch_size <- as.integer(args[i + 1L])
      if (is.na(opts$batch_size) || opts$batch_size < 1L) {
        stop("--batch-size must be a positive integer.")
      }
      i <- i + 2L
    } else if (a == "--no-resume") {
      opts$resume <- FALSE
      i <- i + 1L
    } else if (a == "--execute") {
      # Actually RUN each paper's R code (in an isolated callr subprocess,
      # sandbox = "process") instead of static-only analysis. Runs downloaded,
      # unvetted third-party code on this machine -- see reproducibility_check's
      # own docs for what sandbox = "process" does and does not isolate.
      # This is the DEFAULT (see opts$execute above) -- this flag is kept
      # only so an explicit `--execute` in an existing command still works.
      opts$execute <- TRUE
      i <- i + 1L
    } else if (a == "--no-execute") {
      # Opt OUT of the execute default for a static-only pass (fast: just
      # dependency/path/run-order analysis, no code actually run).
      opts$execute <- FALSE
      i <- i + 1L
    } else if (a == "--timeout") {
      if (i == length(args)) stop("Missing value for ", a)
      opts$timeout <- as.integer(args[i + 1L])
      if (is.na(opts$timeout) || opts$timeout < 1L) {
        stop("--timeout must be a positive integer (seconds).")
      }
      i <- i + 2L
    } else if (a == "--workers") {
      # Number of papers to run CONCURRENTLY in Docker (metacheck >= 0.3.1's
      # reproducibility_check(workers = ...); see run_module_batched_workers()'s
      # own comment). Ignored (falls back to the one-paper-at-a-time path) when
      # execute = FALSE or sandbox is not docker -- see run_repro_check().
      if (i == length(args)) stop("Missing value for ", a)
      opts$workers <- as.integer(args[i + 1L])
      if (is.na(opts$workers) || opts$workers < 1L) {
        stop("--workers must be a positive integer.")
      }
      i <- i + 2L
    } else if (a %in% c("--help", "-h")) {
      message("Usage: Rscript run_reproducibility_check.R [--max-papers N] [--batch-size N] [--no-resume] [--no-execute] [--timeout SECONDS] [--workers N]")
      message("execute = TRUE by default (real code execution); pass --no-execute for a static-only pass.")
      message("--workers N (default 1) runs up to N papers concurrently in Docker (requires execute = TRUE and sandbox = docker, both defaults here).")
      quit(status = 0)
    } else {
      stop("Unknown argument: ", a)
    }
  }
  opts
}

infer_repo_root <- function() {
  # This script lives at <repo_root>/reproducibility_check/, one level
  # below the repo root itself (alongside manuscript/) -- so the repo
  # root is the PARENT of this script's own location, not the location
  # itself. Prefer the location of this script (so it works when run
  # from elsewhere) over getwd(), which depends on the caller's own
  # working directory when the script was launched.
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
  candidates <- c(
    file.path(repo_root, "bes.rds"),
    file.path(repo_root, "manuscript", "data", "bes.rds")
  )
  hit <- candidates[file.exists(candidates)]
  if (length(hit) == 0L) {
    stop(
      "Could not find bes.rds. Expected one of: ",
      paste(candidates, collapse = ", ")
    )
  }
  hit[1L]
}

module_exists <- function(name) {
  if (exists(name, mode = "function", where = asNamespace("metacheck"))) {
    return(TRUE)
  }
  if (is.data.frame(module_list()) && name %in% module_list()$name) {
    return(TRUE)
  }
  FALSE
}

ensure_repro_branch <- function(repo_root) {
  if (!requireNamespace("remotes", quietly = TRUE)) {
    install.packages("remotes", repos = "https://cloud.r-project.org")
  }

  # Always install metacheck fresh from GitHub's dev branch -- never from a
  # locally vendored copy. dev is the reconciled branch (see PR #413) that
  # both the reproducibility_check module and its Docker sandbox backend
  # live on. No early-return on module_exists(): an older metacheck already
  # installed on this machine could already expose a same-named module, and
  # silently keeping that stale copy would defeat "always use dev".
  # Detach/unload BEFORE installing, not after: on Windows, R CMD INSTALL
  # refuses to overwrite a package that is currently loaded in THIS SAME
  # process ("package 'metacheck' is in use and will not be installed"),
  # even though install_local()/install_github() run as ordinary R code in
  # the same session that did library(metacheck) at the top of this script.
  # Detaching first releases that lock so the overwrite can actually happen.
  if ("package:metacheck" %in% search()) {
    detach("package:metacheck", unload = TRUE, character.only = TRUE)
  }

  message("Installing scienceverse/metacheck@dev from GitHub...")
  # Force the reinstall even if remotes thinks the SHA is unchanged; otherwise
  # the same process can keep using the currently loaded package object and the
  # module-check never sees the newly-installed files.
  remotes::install_github(
    "scienceverse/metacheck",
    ref = "dev",
    upgrade = "never",
    force = TRUE
  )

  suppressPackageStartupMessages(library(metacheck))

  file_on_disk <- system.file("modules/reproducibility_check.R", package = "metacheck")
  if (!nzchar(file_on_disk) || !file.exists(file_on_disk)) {
    stop(
      "The reproducibility_check module file is not present in the installed package. ",
      "The branch install likely failed or the branch name is different."
    )
  }

  if (!module_exists("reproducibility_check")) {
    stop(
      "The reproducibility_check module is not present in the installed package. ",
      "scienceverse/metacheck@dev is not currently exposing this feature."
    )
  }

  invisible(TRUE)
}

# == Batching / checkpointing helpers ============================================
# Same pattern as manuscript/code_data_preparation/helpers.R's
# status()/run_with_warnings()/combine_batches(), inlined here so this script
# stays runnable standalone from the repo root (that helpers.R is sourced
# relative to manuscript/, a different working directory).

status <- function(...) {
  cat(sprintf("[%s] %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
              sprintf(...)))
  utils::flush.console()
}

# R's default non-interactive behaviour defers warnings and, once more than
# 50 accumulate, prints only a count at the end -- forward every warning to
# WARNING_LOG as it happens instead, so a long run's warnings are not lost.
run_with_warnings <- function(module_name, warning_log, ...) {
  withCallingHandlers(
    module_run(...),
    warning = function(w) {
      cat(sprintf("[%s] %s: %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
                  module_name, conditionMessage(w)),
          file = warning_log, append = TRUE)
      invokeRestart("muffleWarning")
    }
  )
}

# Combine a list of per-batch metacheck_module_output objects into one
# corpus-wide object with the same shape module_run() itself produces.
combine_batches <- function(batches) {
  all_fields <- unique(unlist(lapply(batches, names)))
  is_df <- function(x) is.data.frame(x)

  out <- list()
  for (f in all_fields) {
    vals <- lapply(batches, `[[`, f)
    vals <- vals[!vapply(vals, is.null, logical(1))]
    if (length(vals) == 0) next

    if (f %in% c("module", "title", "section")) {
      out[[f]] <- vals[[1]]
    } else if (f == "paper") {
      out[[f]] <- do.call(paperlist, vals)
    } else if (f == "previews") {
      out[[f]] <- do.call(c, vals)
    } else if (all(vapply(vals, is_df, logical(1)))) {
      nonempty <- vals[vapply(vals, nrow, integer(1)) > 0]
      out[[f]] <- if (length(nonempty) > 0) dplyr::bind_rows(nonempty) else vals[[1]]
    } else {
      out[[paste0(f, "_by_batch")]] <- vals
    }
  }
  out
}

# Run `module_name` over `papers` BATCH_SIZE papers at a time, saving each
# batch's result to `batch_dir` as soon as it finishes. `resume = TRUE`
# (default) skips a batch whose result file already exists. A batch that
# errors is logged and left unsaved (so a later re-run retries it) rather
# than aborting the whole corpus run.
run_module_batched <- function(papers, module_name, batch_dir, warning_log,
                               batch_size = 50L, resume = TRUE,
                               variant = "", ...) {
  n <- length(papers)
  starts <- seq(1L, n, by = batch_size)
  nb <- length(starts)
  status("Processing %d papers in %d batch(es) of up to %d papers each.",
         n, nb, batch_size)

  var_name <- paste0("res_", module_name)
  batch_results <- vector("list", nb)

  for (b in seq_len(nb)) {
    batch_id <- sprintf("%03d", b)
    s <- starts[b]
    e <- min(s + batch_size - 1L, n)
    # batch_size is part of the filename, not just variant: a checkpoint from
    # a DIFFERENT --batch-size covers a different paper range under the same
    # batch NUMBER (e.g. batch004 at size 5 is papers 16-20, at size 50 is
    # papers 151-200) -- silently trusting a same-numbered file from a prior
    # run with a different batch size corrupts the combined result with
    # duplicate/wrong-scope rows. Confirmed as a real, live incident: 4
    # leftover batch_size=50 files, never cleaned up, got silently reused by
    # a later batch_size=5 run after their own same-numbered (correct) files
    # failed and were left unsaved, producing 200 duplicated paper_id rows
    # (4 files x 50 papers) and 20 missing papers in the combined output.
    path <- file.path(batch_dir, sprintf("res_%s%s_bs%d_batch%s.RData", module_name, variant, batch_size, batch_id))

    if (resume && file.exists(path)) {
      status("Batch %d/%d (papers %d-%d): already done, loading from disk.", b, nb, s, e)
      env <- new.env()
      load(path, envir = env)
      batch_results[[b]] <- env[[var_name]]
      next
    }

    status("Batch %d/%d (papers %d-%d): running %s...", b, nb, s, e, module_name)
    batch_papers <- papers[s:e]
    res <- tryCatch(
      run_with_warnings(module_name, warning_log, batch_papers, module_name, ...),
      error = function(err) {
        status("Batch %d/%d FAILED (%s) -- skipping; rerun this script later to retry just this batch.",
               b, nb, conditionMessage(err))
        NULL
      }
    )
    if (!is.null(res)) {
      assign(var_name, res)
      save(list = var_name, file = path)
      status("Batch %d/%d done.", b, nb)
    }
    batch_results[[b]] <- res
  }

  batch_results
}

# Same as run_module_batched(), but calls `module_name` ONCE PER PAPER inside
# each batch rather than once for the whole batch. reproducibility_check()
# (unlike code_check/data_check/repo_check) is not written to process a
# multi-paper paperlist: it tracks a single paper_id throughout (via its own
# internal .pid() helper) and never splits its output by paper_id, so handing
# it a batch of several papers at once silently collapses to an empty result
# for the WHOLE batch (confirmed live: match_table was NULL and
# repro_tests_reported/repro_tests_matched were NA for every paper in a
# batch-of-5 run, while calling the identical module on one of those same
# papers alone produced a real match_table). Batch-level checkpointing is
# kept (one saved file per batch, resumable the same way) by running each
# paper individually and combining the per-paper results with the same
# combine_batches() this script already uses to combine batches themselves.
run_module_batched_per_paper <- function(papers, module_name, batch_dir, warning_log,
                                         batch_size = 50L, resume = TRUE,
                                         variant = "", ...) {
  n <- length(papers)
  starts <- seq(1L, n, by = batch_size)
  nb <- length(starts)
  status("Processing %d papers in %d batch(es) of up to %d papers each (calling %s one paper at a time).",
         n, nb, batch_size, module_name)

  var_name <- paste0("res_", module_name)
  batch_results <- vector("list", nb)

  for (b in seq_len(nb)) {
    batch_id <- sprintf("%03d", b)
    s <- starts[b]
    e <- min(s + batch_size - 1L, n)
    path <- file.path(batch_dir, sprintf("res_%s%s_bs%d_batch%s.RData", module_name, variant, batch_size, batch_id))

    if (resume && file.exists(path)) {
      status("Batch %d/%d (papers %d-%d): already done, loading from disk.", b, nb, s, e)
      env <- new.env()
      load(path, envir = env)
      batch_results[[b]] <- env[[var_name]]
      next
    }

    status("Batch %d/%d (papers %d-%d): running %s on %d paper(s), one at a time...",
           b, nb, s, e, module_name, e - s + 1L)
    paper_results <- vector("list", e - s + 1L)
    for (k in seq_len(e - s + 1L)) {
      idx <- s + k - 1L
      one_paper <- papers[idx]
      pid <- tryCatch(paper_id(one_paper), error = function(err) NA_character_)
      status("  Paper %d/%d in batch (%s)...", k, e - s + 1L, pid)
      res_i <- tryCatch(
        run_with_warnings(module_name, warning_log, one_paper, module_name, ...),
        error = function(err) {
          status("  Paper %d/%d FAILED (%s) -- skipping this paper.", k, e - s + 1L, conditionMessage(err))
          NULL
        }
      )
      paper_results[[k]] <- res_i
    }
    paper_results <- Filter(Negate(is.null), paper_results)

    if (length(paper_results) > 0) {
      res <- combine_batches(paper_results)
      assign(var_name, res)
      save(list = var_name, file = path)
      status("Batch %d/%d done (%d/%d papers succeeded).", b, nb, length(paper_results), e - s + 1L)
    } else {
      status("Batch %d/%d FAILED (no papers in this batch succeeded) -- skipping; rerun this script later to retry.",
             b, nb)
      res <- NULL
    }
    batch_results[[b]] <- res
  }

  batch_results
}

# Same outer batch-file checkpointing as run_module_batched_per_paper(), but
# hands each outer batch's WHOLE paperlist to reproducibility_check() in one
# call with workers = <n>, instead of looping one paper at a time within the
# batch. metacheck >= 0.3.1 added native support for this (see
# reproducibility_check()'s own `workers`/`results_dir` args): when
# `execute = TRUE` and `sandbox = "docker"`, passing a paperlist of length > 1
# with workers > 1 runs that many papers CONCURRENTLY, each in its own
# background R process/container, internally still calling module_run() ONE
# PAPER AT A TIME per worker (so the old "multi-paper paperlist collapses to
# an empty result" limitation run_module_batched_per_paper()'s own comment
# describes does not apply here -- that was about handing several papers to a
# single reproducibility_check() call, not about several concurrent
# single-paper calls) and combining their results the same way
# combine_batches() below already does by hand. Falls back to the old
# per-paper-sequential behaviour automatically whenever workers <= 1 or the
# batch has only one paper (reproducibility_check()'s own workers argument is
# simply ignored in that case, not an error).
#
# results_dir points at a per-paper .rds checkpoint folder (one file per
# paper_id, written the moment that paper finishes) INSIDE this outer batch's
# own scope -- a second, finer-grained resumability layer underneath the
# existing per-batch .RData files, so a run killed mid-batch does not lose
# the papers that already finished within that still-unsaved batch.
run_module_batched_workers <- function(papers, module_name, batch_dir, warning_log,
                                       batch_size = 50L, resume = TRUE,
                                       variant = "", workers = 1L, ...) {
  n <- length(papers)
  starts <- seq(1L, n, by = batch_size)
  nb <- length(starts)
  status("Processing %d papers in %d batch(es) of up to %d papers each (up to %d worker(s) concurrently).",
         n, nb, batch_size, workers)

  var_name <- paste0("res_", module_name)
  batch_results <- vector("list", nb)
  results_root <- file.path(batch_dir, "worker_results")

  for (b in seq_len(nb)) {
    batch_id <- sprintf("%03d", b)
    s <- starts[b]
    e <- min(s + batch_size - 1L, n)
    path <- file.path(batch_dir, sprintf("res_%s%s_bs%d_batch%s.RData", module_name, variant, batch_size, batch_id))

    if (resume && file.exists(path)) {
      status("Batch %d/%d (papers %d-%d): already done, loading from disk.", b, nb, s, e)
      env <- new.env()
      load(path, envir = env)
      batch_results[[b]] <- env[[var_name]]
      next
    }

    status("Batch %d/%d (papers %d-%d): running %s on %d paper(s), up to %d at a time...",
           b, nb, s, e, module_name, e - s + 1L, workers)
    batch_papers <- papers[s:e]
    results_dir <- file.path(results_root, sprintf("batch%s", batch_id))
    dir.create(results_dir, showWarnings = FALSE, recursive = TRUE)
    res <- tryCatch(
      run_with_warnings(module_name, warning_log, batch_papers, module_name,
                        workers = workers, results_dir = results_dir, ...),
      error = function(err) {
        status("Batch %d/%d FAILED (%s) -- skipping; rerun this script later to retry just this batch.",
               b, nb, conditionMessage(err))
        NULL
      }
    )
    if (!is.null(res)) {
      assign(var_name, res)
      save(list = var_name, file = path)
      status("Batch %d/%d done.", b, nb)
    }
    batch_results[[b]] <- res
  }

  batch_results
}

run_repro_check <- function(papers, repo_root, batch_size, resume,
                            execute = TRUE, timeout = 3000L, workers = 1L) {
  data_dir <- file.path(repo_root, "data")
  batch_dir <- file.path(data_dir, "batches")
  dir.create(batch_dir, showWarnings = FALSE, recursive = TRUE)
  # Separate suffix for an execute = TRUE run: its batch checkpoints and
  # final combined output must never be confused with (or silently reused
  # as a stand-in for) the static-only (execute = FALSE) results already
  # computed for the full corpus -- these are answering a materially
  # different question (does the code actually run vs. does it merely look
  # ready to run) and mixing them up would misreport which is which.
  variant <- if (isTRUE(execute)) "_execute" else ""
  warning_log <- file.path(data_dir, sprintf("reproducibility_check%s_warnings.log", variant))

  if (!module_exists("reproducibility_check")) {
    # Unreachable in normal use: main() always calls ensure_repro_branch()
    # first, which either makes the module available or stops(). Kept as a
    # defensive fallback (not batched -- this path is not expected to run
    # against the full corpus) in case this function is ever called without
    # that guarantee in the future.
    message(
      "No dedicated reproducibility_check module was detected; falling back to ",
      "repo_check -> data_check -> code_check (single call, not batched/resumable)."
    )
    res_repo <- module_run(papers, "repo_check", osf_license = TRUE)
    res_data <- module_run(res_repo, "data_check", cache = TRUE)
    res_code <- module_run(res_data, "code_check", cache = TRUE)
    return(list(
      module = "repo_check->data_check->code_check",
      results = list(repo_check = res_repo, data_check = res_data, code_check = res_code),
      dataset = length(papers),
      output_path = file.path(data_dir, "reproducibility_check_results.RData")
    ))
  }

  message("Detected dedicated reproducibility_check module. Running it ",
          if (isTRUE(execute) && workers > 1L) paste0("up to ", workers, " papers at a time")
          else "one paper at a time",
          " (checkpointed in batches of ", batch_size, ")",
          if (isTRUE(execute)) " (execute = TRUE: code will actually run)." else ".")

  # execute = TRUE additionally installs the declared dependencies and
  # actually runs each script -- sandbox = "docker" runs each script inside
  # a locked-down container (network disabled, filesystem read-only outside
  # the sandbox, non-root user) instead of a bare callr subprocess on this
  # machine, a real containment boundary for running downloaded third-party
  # code. By default this uses ghcr.io/scienceverse/metacheck_r:latest,
  # which already has the ~750 most common corpus packages installed, so
  # most papers skip most of the install phase. install_missing = TRUE still
  # installs any further declared dependencies (into a throwaway per-run
  # library inside the container -- see repro_install_deps_docker()).
  # cran_install_main is intentionally omitted here: it is documented as
  # ignored under sandbox = "docker" (a container never has access to the
  # host's main R library; every install always goes into that throwaway
  # library regardless of this argument).
  extra_args <- if (isTRUE(execute)) {
    list(execute = TRUE, sandbox = "docker", install_missing = TRUE,
        timeout = timeout)
  } else list()

  # skip_on_api_limit = TRUE: an unattended, hours-long corpus run must never
  # block synchronously on a host's own daily quota reset (seen live: Dryad's
  # zip quota, 100/day, stricter than its per-file quota -- a "wait 5.6 hours"
  # message on batch 1 of a 373-batch run). Skipping that file/download and
  # moving on is the right default here; it only affects data actually pulled
  # from a rate-limited host, not the paper's other files.
  #
  # workers > 1 (and execute = TRUE, sandbox = "docker" via extra_args) uses
  # metacheck >= 0.3.1's native concurrent-papers batch dispatcher (see
  # run_module_batched_workers()'s own comment); otherwise falls back to the
  # pre-existing one-paper-at-a-time path unchanged.
  batcher <- if (isTRUE(execute) && workers > 1L) run_module_batched_workers else run_module_batched_per_paper
  batch_results <- do.call(batcher, c(
    list(papers, "reproducibility_check", batch_dir, warning_log,
        batch_size = batch_size, resume = resume, variant = variant, cache = TRUE,
        skip_on_api_limit = TRUE),
    if (isTRUE(execute) && workers > 1L) list(workers = workers) else list(),
    extra_args
  ))

  ok <- !vapply(batch_results, is.null, logical(1))
  if (!all(ok)) {
    status(paste0("%d of %d batches did NOT complete -- their papers are missing from the ",
                  "combined output below. Re-run this script to retry just those batches."),
           sum(!ok), length(ok))
  }
  combined <- combine_batches(Filter(Negate(is.null), batch_results))

  list(
    module = "reproducibility_check",
    execute = execute,
    results = combined,
    dataset = length(papers),
    n_batches = length(batch_results),
    n_batches_ok = sum(ok),
    output_path = file.path(data_dir, sprintf("reproducibility_check_results%s.RData", variant))
  )
}

main <- function() {
  opts <- parse_args(commandArgs(trailingOnly = TRUE))
  repo_root <- infer_repo_root()
  cat("Repo root: ", repo_root, "\n", sep = "")
  cat("metacheck version: ", as.character(packageVersion("metacheck")), "\n", sep = "")

  # Share ONE cache location with manuscript/code_data_preparation/01_run_checks.R
  # (which runs with manuscript/ as its working directory) instead of each
  # process defaulting to a folder relative to ITS OWN cwd. Without this, this
  # script's repo root and that pipeline's manuscript/ working directory each
  # grew their own separate .metacheck_repo_cache / .metacheck_repo_info_cache
  # -- confirmed live: ~40GB of downloaded repo files ended up duplicated in
  # both locations, doubled again by OneDrive syncing the whole project
  # folder. manuscript/ is the pre-existing, larger, actively-used-by-another-
  # script location, so this script conforms to it rather than the other way
  # around.
  options(metacheck.cache.dir = file.path(repo_root, "manuscript"))
  cat("metacheck cache dir: ", file.path(repo_root, "manuscript"), "\n", sep = "")

  ensure_repro_branch(repo_root)

  bes_path <- locate_bes(repo_root)
  cat("Loading corpus from: ", bes_path, "\n", sep = "")
  bes <- readRDS(bes_path)

  if (!is.null(opts$max_papers)) {
    n <- min(length(bes), opts$max_papers)
    cat("Subsetting to first ", n, " papers for this run.\n", sep = "")
    bes <- bes[seq_len(n)]
  }

  data_dir <- file.path(repo_root, "data")
  if (!dir.exists(data_dir)) {
    dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)
  }

  out <- run_repro_check(bes, repo_root, batch_size = opts$batch_size, resume = opts$resume,
                         execute = opts$execute, timeout = opts$timeout, workers = opts$workers)

  save(out, file = out$output_path)
  cat("Saved combined output to: ", out$output_path, "\n", sep = "")
  if (!is.null(out$n_batches)) {
    cat("Batches complete: ", out$n_batches_ok, " / ", out$n_batches, "\n", sep = "")
  }

  if (!is.null(out$results$table)) {
    cat("results table rows: ", nrow(out$results$table), "\n", sep = "")
  }
  if (!is.null(out$results$summary_table)) {
    cat("results summary_table rows: ", nrow(out$results$summary_table), "\n", sep = "")
  }
  # Fallback-path reporting (repo_check->data_check->code_check shape).
  if (!is.null(out$results$repo_check)) {
    cat("repo_check rows: ", nrow(out$results$repo_check$table), "\n", sep = "")
  }
  if (!is.null(out$results$data_check)) {
    cat("data_check rows: ", nrow(out$results$data_check$table), "\n", sep = "")
  }
  if (!is.null(out$results$code_check)) {
    cat("code_check rows: ", nrow(out$results$code_check$table), "\n", sep = "")
  }

  cat("Finished.\n")
}

main()
