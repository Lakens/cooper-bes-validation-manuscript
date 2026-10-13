# Targeted rerun of every paper with at least one data or code file inside
# an archive (zip/tar) that the corpus run listed but never downloaded
# (file_location NA). Reviewing the 24 unreviewed code_download
# disagreements (2026-10-10) showed that, for every one of them, the
# installed metacheck downloads the same archive member correctly when
# called live -- so the corpus-run failure was specific to that run, most
# plausibly a host rate limit hit with skip_on_api_limit = TRUE (the corpus
# default), which skips a download silently rather than waiting. The
# corpus run kept no record of why, because data_check()/code_check() only
# log failed downloads to a manifest when `manifest` is given, and no run
# script passed it.
#
# Differences from the corpus run, and why:
#   - skip_on_api_limit = FALSE: wait out a rate limit instead of skipping.
#   - manifest = <folder>: data_check() and code_check() write, per paper,
#     every file's download outcome -- including each failed download and
#     its error -- to <folder>/<paper_id>.manifest.json, so any download
#     that still fails is recorded with its reason. For data files this
#     also separates real failures from files deliberately not downloaded
#     (per-file / per-repository size limits), which the corpus result
#     cannot tell apart.
#   - cache = TRUE (unlike script 12's cache = FALSE): listings and files
#     already on the D: cache are reused, so only the missing files are
#     fetched. The cache drive must be attached.
#   - Batches of 20 papers, each saved to disk as it completes, so an
#     interrupted run resumes where it stopped instead of starting over.
#
# Merging into the corpus-wide files uses the same drop_ids()/
# combine_batches() helpers as scripts 03-12.
#
# Usage (from inside code/): Rscript 01_run_metacheck/13_rerun_failed_archive_downloads.R

library(metacheck)
library(dplyr)

# Cache root: D:/ (the external cache drive) unless METACHECK_CACHE_ROOT says
# otherwise, e.g. "C:/" as a fallback when D: is unavailable. A new root
# starts with an empty cache, so everything is downloaded again there.
cache_root <- Sys.getenv("METACHECK_CACHE_ROOT", "D:/")
options(metacheck.cache.dir = cache_root)
if (cache_root == "D:/") stopifnot(dir.exists("D:/.metacheck_repo_cache"))

status <- function(...) {
  cat(sprintf("[%s] %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), sprintf(...)))
  utils::flush.console()
}

status("Cache root: %s", cache_root)
status("metacheck version: %s (RemoteSha %s)", as.character(packageVersion("metacheck")),
       utils::packageDescription("metacheck")[["RemoteSha"]] %||% "unknown")

out_dir <- "01_run_metacheck/rerun_failed_archive_downloads"
batch_dir <- file.path(out_dir, "batches")
manifest_dir <- file.path(out_dir, "manifests")
dir.create(batch_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(manifest_dir, showWarnings = FALSE, recursive = TRUE)

strip_paper_text <- function(res) {
  res$paper <- NULL
  res
}

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

drop_ids <- function(res, ids) {
  for (f in names(res)) {
    x <- res[[f]]
    if (is.data.frame(x) && "paper_id" %in% names(x)) {
      res[[f]] <- x[!(x$paper_id %in% ids), ]
    }
  }
  res
}

# ── 1. Which papers ──────────────────────────────────────────────────────────
ids_file <- file.path(out_dir, "rerun_ids.csv")
if (file.exists(ids_file)) {
  rerun_ids <- read.csv(ids_file, stringsAsFactors = FALSE)$paper_id
  status("Reusing paper list from %s (%d papers).", ids_file, length(rerun_ids))
} else {
  status("Finding papers with undownloaded archive members...")
  undownloaded_archive_ids <- function(tbl) {
    am <- !is.na(tbl$archive_member) & nzchar(tbl$archive_member)
    nl <- is.na(tbl$file_location) | !nzchar(tbl$file_location)
    unique(tbl$paper_id[am & nl])
  }
  load("01_run_metacheck/res_data_check.RData")
  st <- res_data_check$structure
  data_ids <- undownloaded_archive_ids(st[st$data_type %in% "data", ])
  rm(res_data_check, st); invisible(gc())
  load("01_run_metacheck/res_code_check.RData")
  code_ids <- undownloaded_archive_ids(res_code_check$table)
  rm(res_code_check); invisible(gc())
  rerun_ids <- sort(union(data_ids, code_ids))
  write.csv(data.frame(paper_id = rerun_ids,
                       data_archive_member_missing = rerun_ids %in% data_ids,
                       code_archive_member_missing = rerun_ids %in% code_ids),
            ids_file, row.names = FALSE)
  status("%d papers (%d with data, %d with code archive members missing); list saved to %s.",
         length(rerun_ids), length(data_ids), length(code_ids), ids_file)
}

# ── 2. Rerun in resumable batches ────────────────────────────────────────────
status("Loading corpus (data/bes.rds)...")
bes <- readRDS("data/bes.rds")
stopifnot(all(rerun_ids %in% names(bes)))

# Papers in an already-saved batch (from the earlier batch-of-20 version of
# this script) are done; every other paper is run ONE AT A TIME below.
batches <- split(rerun_ids, ceiling(seq_along(rerun_ids) / 20))
batch_files <- file.path(batch_dir, sprintf("batch_%02d.rds", seq_along(batches)))
done_in_batches <- unlist(batches[file.exists(batch_files)])
status("%d papers already done in %d saved batch(es).", length(done_in_batches), sum(file.exists(batch_files)))

# Why one paper at a time, each in its own R process, under a watchdog: a
# metacheck web request has no time limit, so a connection that stalls
# without closing makes the whole run wait forever (2026-10-11: zip_peek()'s
# 1 MB range request to Zenodo record 6654689, paper 10_1111_1365_2664_13374,
# trickled at ~7 KB/s and then stalled; twice the whole batch of 20 hung for
# 40+ minutes). Each paper now runs in a callr background process whose
# output goes to its own log file; if that file does not grow for
# HANG_MINUTES the process is stopped and the paper recorded as hung. A
# host rate-limit wait does not trigger this: metacheck prints a countdown
# every second while it waits. Hung papers are retried once at the end; a
# paper that still fails keeps its ORIGINAL corpus rows (it is not dropped
# in the merge below). Each finished paper is saved immediately, so a crash
# loses at most the paper in progress.
HANG_MINUTES <- 15
paper_dir <- file.path(out_dir, "papers")
plog_dir <- file.path(out_dir, "paper_logs")
dir.create(paper_dir, showWarnings = FALSE); dir.create(plog_dir, showWarnings = FALSE)

run_one_paper <- function(paper_file, cache_root, manifest_dir, out_file, budget_mb = 2000,
                          skip_limit = FALSE) {
  suppressMessages(library(metacheck))
  options(metacheck.cache.dir = cache_root)
  p <- readRDS(paper_file)
  strip <- function(res) { res$paper <- NULL; res }
  # max_download_size = 2000 (MB; default 500): metacheck downloads a Dryad
  # archive whole -- ONE request -- only when it fits this budget (#471);
  # above it, it fetches members one by one at two requests each, and
  # Dryad's hourly request limit then stalls a single paper for many hours
  # (2026-10-11: paper 13628, a 0.66 GB archive of 310 files). 2 GB covers
  # 78 of the 80 remaining Dryad archives.
  r_repo <- module_run(p, "repo_check", osf_license = TRUE, cache = TRUE)
  r_data <- module_run(r_repo, "data_check", cache = TRUE, skip_on_api_limit = skip_limit,
                       manifest = manifest_dir, max_download_size = budget_mb)
  r_code <- module_run(r_data, "code_check", cache = TRUE, skip_on_api_limit = skip_limit,
                       manifest = manifest_dir, max_download_size = budget_mb)
  saveRDS(list(repo = strip(r_repo), data = strip(r_data), code = strip(r_code)), out_file)
  invisible(TRUE)
}

# Papers whose Dryad archive is larger than the 2 GB budget would otherwise
# be fetched member by member (12774: 1,457 files, ~3,000 requests). Give
# them a budget above the archive's size so it is downloaded whole in one
# request (sizes from the archive listing, uncompressed: 7.3 and 21.8 GB).
big_budget <- c("10_1111_2041_210x_12774" = 10000, "10_1111_2041_210x_13206" = 25000)

# Dryad limits downloads per hour (undocumented; refusals carry waits of up
# to ~60 min, and a paper needing many Dryad files can wait several hours,
# 2026-10-11: paper 13720, 95 min and counting). In the first pass, a
# paper whose log shows a Dryad wait of DRYAD_DEFER_MINUTES or longer is
# stopped and deferred, so the rest of the run is not held up. The final
# pass reruns every unfinished paper with skip_on_api_limit = TRUE:
# metacheck then downloads whatever Dryad allows and skips (and records in
# the manifest) the rest instead of waiting -- partial downloads are fine
# for this comparison, which only needs to know whether data/code files can
# be found and fetched at all.
DRYAD_DEFER_MINUTES <- 5
dryad_wait_minutes <- function(log_file) {
  if (!file.exists(log_file)) return(0)
  txt <- paste(readLines(log_file, warn = FALSE), collapse = "\n")
  m <- regmatches(txt, gregexpr("datadryad\\.org; waiting [0-9.]+ (min|hours)", txt))[[1]]
  if (!length(m)) return(0)
  v <- as.numeric(sub(".*waiting ([0-9.]+) .*", "\\1", m))
  max(ifelse(grepl("hours", m), v * 60, v))
}

# Papers run N_WORKERS at a time (2026-10-11: most papers spend their time
# waiting on the network, so two at once roughly halves the run; kept at 2
# rather than more because the D: cache drive has disconnected under heavy
# load). Each paper still runs in its own callr process under the same
# watchdog rules. Two papers that cite the same repository are never run at
# the same time, so they cannot write the same cache files concurrently.
N_WORKERS <- 2

load("01_run_metacheck/res_repo_check.RData")   # res_repo_check, for paper -> repositories
paper_repos <- split(res_repo_check$table$repo_url, res_repo_check$table$paper_id)
rm(res_repo_check); invisible(gc())

# "Active" = the log grew, OR the process used processor time, OR it read
# or transferred data (Windows I/O counters, which include network
# traffic). Output alone is not enough: data_check summarises large cached
# files and fetches zip members silently for long stretches (2026-10-11:
# papers 13539 and 13614 were wrongly stopped that way). A true stall --
# what the watchdog exists for -- shows none of the three.
io_of <- function(pid) {
  out <- suppressWarnings(system2("powershell", c("-NoProfile", "-Command",
    shQuote(sprintf("$p = Get-CimInstance Win32_Process -Filter 'ProcessId=%d'; if ($p) { $p.ReadTransferCount + $p.OtherTransferCount }", pid))),
    stdout = TRUE, stderr = FALSE))
  suppressWarnings(as.numeric(out[length(out)]))
}

start_paper <- function(id, final_pass) {
  budget_mb <- if (id %in% names(big_budget)) big_budget[[id]] else 2000
  out_file <- file.path(paper_dir, paste0(id, ".rds"))
  log_file <- file.path(plog_dir, paste0(id, ".log"))
  paper_file <- file.path(tempdir(), paste0(id, "_paper.rds"))
  saveRDS(bes[id], paper_file)
  proc <- callr::r_bg(run_one_paper,
                      args = list(paper_file, cache_root, normalizePath(manifest_dir, mustWork = FALSE),
                                  normalizePath(out_file, mustWork = FALSE), budget_mb, final_pass),
                      stdout = log_file, stderr = "2>&1", supervise = TRUE)
  st <- new.env()
  st$id <- id; st$proc <- proc; st$out_file <- out_file; st$log_file <- log_file
  st$final_pass <- final_pass; st$t0 <- Sys.time(); st$last_change <- Sys.time()
  st$last_size <- -1; st$last_cpu <- -1; st$last_io <- -1; st$tick <- 0
  st$repos <- unique(paper_repos[[id]])
  st
}

# One watchdog check of a running paper (called every 15 s). Returns
# "running", or the paper's final outcome.
check_paper <- function(st) {
  if (!st$proc$is_alive()) return(if (file.exists(st$out_file)) "ok" else "failed")
  st$tick <- st$tick + 1
  sz <- if (file.exists(st$log_file)) file.info(st$log_file)$size else 0
  if (!identical(sz, st$last_size)) { st$last_size <- sz; st$last_change <- Sys.time() }
  if (st$tick %% 4 == 0) {                       # every minute: processor and I/O
    # Minimum levels, not just "any": a stalled Zenodo range request still
    # trickles ~1 KB/s with ~2% processor use (2026-10-11, paper 13374),
    # which must count as stalled. Real work clears at least one of: 6 s
    # of processor time (10%) or 1 MB transferred per minute.
    cpu <- tryCatch(sum(st$proc$get_cpu_times()[c("user", "system")], na.rm = TRUE),
                    error = function(e) NA_real_)
    io <- io_of(st$proc$get_pid())
    if (!is.na(cpu) && st$last_cpu >= 0 && cpu - st$last_cpu >= 6) st$last_change <- Sys.time()
    if (length(io) == 1 && !is.na(io) && st$last_io >= 0 && io - st$last_io >= 1048576) st$last_change <- Sys.time()
    if (!is.na(cpu)) st$last_cpu <- cpu
    if (length(io) == 1 && !is.na(io)) st$last_io <- io
    if (!st$final_pass && dryad_wait_minutes(st$log_file) >= DRYAD_DEFER_MINUTES) {
      st$proc$kill(); return("dryad-deferred")
    }
  }
  if (difftime(Sys.time(), st$last_change, units = "mins") > HANG_MINUTES) {
    st$proc$kill(); return("hung")
  }
  "running"
}

todo <- setdiff(rerun_ids, done_in_batches)
# Not rerun at all, keeping their corpus results: 14383 cites SAPFLUXNET
# (Zenodo 3971689, 3,983 files, 23 GB). data_check reads and summarises its
# 3,106 data files one by one (~165 per 50 minutes, so ~15 hours for this
# one paper, 2026-10-11) -- real processing that neither watchdog rule
# stops, and that the final pass would repeat.
skip_ids <- "10_1111_1365_2664_14383"
todo <- setdiff(todo, skip_ids)
# Known to stall (Zenodo record 6654689, see above): run it last, so it
# cannot hold up the others.
defer <- c("10_1111_1365_2664_13374", names(big_budget))
todo <- c(setdiff(todo, defer), intersect(todo, defer))
for (attempt in 1:2) {
  todo <- todo[!file.exists(file.path(paper_dir, paste0(todo, ".rds")))]
  if (length(todo) == 0) break
  final_pass <- attempt == 2
  status("Attempt %d: %d paper(s) to run, %d at a time%s.", attempt, length(todo), N_WORKERS,
         if (final_pass) " (final pass: skip_on_api_limit = TRUE, partial downloads accepted)" else "")
  queue <- todo; running <- list(); n_finished <- 0
  while (length(queue) > 0 || length(running) > 0) {
    # Fill free worker slots, skipping any paper that shares a repository
    # with a paper already running (it waits in the queue instead).
    while (length(running) < N_WORKERS && length(queue) > 0) {
      busy <- unlist(lapply(running, function(s) s$repos))
      pick <- which(vapply(queue, function(id) !any(unique(paper_repos[[id]]) %in% busy), logical(1)))
      if (length(pick) == 0) break
      id <- queue[pick[1]]; queue <- queue[-pick[1]]
      running[[id]] <- start_paper(id, final_pass)
    }
    Sys.sleep(15)
    for (id in names(running)) {
      res <- check_paper(running[[id]])
      if (res == "running") next
      n_finished <- n_finished + 1
      n_done <- length(done_in_batches) + length(list.files(paper_dir, "[.]rds$"))
      status("Paper %d/%d %s: %s (%.0f min). Done %d of %d, left %d.", n_finished, length(todo), id, res,
             as.numeric(difftime(Sys.time(), running[[id]]$t0, units = "mins")), n_done,
             length(rerun_ids), length(rerun_ids) - n_done)
      running[[id]] <- NULL
    }
  }
}

# ── 3. Combine batches and per-paper results, report, merge ─────────────────
done_batches <- lapply(batch_files[file.exists(batch_files)], readRDS)
done_papers <- lapply(list.files(paper_dir, "[.]rds$", full.names = TRUE), readRDS)
done <- c(done_batches, done_papers)
rerun_ok <- union(done_in_batches, sub("[.]rds$", "", list.files(paper_dir, "[.]rds$")))
not_rerun <- setdiff(rerun_ids, rerun_ok)
status("%d of %d papers rerun; %d kept their original results: %s", length(rerun_ok), length(rerun_ids),
       length(not_rerun), paste(not_rerun, collapse = ", "))
writeLines(not_rerun, file.path(out_dir, "not_rerun_ids.txt"))
res_repo_check_new <- combine_batches(lapply(done, `[[`, "repo"))
res_data_check_new <- combine_batches(lapply(done, `[[`, "data"))
res_code_check_new <- combine_batches(lapply(done, `[[`, "code"))
save(res_repo_check_new, file = file.path(out_dir, "res_repo_check_new.RData"))
save(res_data_check_new, file = file.path(out_dir, "res_data_check_new.RData"))
save(res_code_check_new, file = file.path(out_dir, "res_code_check_new.RData"))

missing_after <- function(tbl) {
  am <- !is.na(tbl$archive_member) & nzchar(tbl$archive_member)
  c(archive_members = sum(am), still_missing = sum(am & (is.na(tbl$file_location) | !nzchar(tbl$file_location))))
}
st_new <- res_data_check_new$structure
status("After rerun -- data archive members: %s", paste(names(missing_after(st_new[st_new$data_type %in% "data", ])),
       missing_after(st_new[st_new$data_type %in% "data", ]), sep = "=", collapse = ", "))
status("After rerun -- code archive members: %s", paste(names(missing_after(res_code_check_new$table)),
       missing_after(res_code_check_new$table), sep = "=", collapse = ", "))
status("Per-paper download logs: %d manifest files in %s.", length(list.files(manifest_dir)), manifest_dir)

status("Loading existing corpus-wide results to merge into...")
load("01_run_metacheck/res_repo_check.RData")  # res_repo_check
load("01_run_metacheck/res_data_check.RData")  # res_data_check
load("01_run_metacheck/res_code_check.RData")  # res_code_check

# Drop only the papers that were actually rerun; a paper that hung twice
# keeps its original rows.
res_repo_check_merged <- combine_batches(list(drop_ids(res_repo_check, rerun_ok), res_repo_check_new))
res_data_check_merged <- combine_batches(list(drop_ids(res_data_check, rerun_ok), res_data_check_new))
res_code_check_merged <- combine_batches(list(drop_ids(res_code_check, rerun_ok), res_code_check_new))

stopifnot(nrow(res_repo_check_merged$summary_table) == nrow(res_repo_check$summary_table))
stopifnot(nrow(res_data_check_merged$summary_table) == nrow(res_data_check$summary_table))
stopifnot(nrow(res_code_check_merged$summary_table) == nrow(res_code_check$summary_table))
status("Row-count check passed (%d/%d/%d).", nrow(res_repo_check_merged$summary_table),
       nrow(res_data_check_merged$summary_table), nrow(res_code_check_merged$summary_table))

status("Skipping backup copy step (limited disk space; previous versions are in git LFS) -- writing directly.")
res_repo_check <- strip_paper_text(res_repo_check_merged)
res_data_check <- strip_paper_text(res_data_check_merged)
res_code_check <- strip_paper_text(res_code_check_merged)
save(res_repo_check, file = "01_run_metacheck/res_repo_check.RData")
save(res_data_check, file = "01_run_metacheck/res_data_check.RData")
save(res_code_check, file = "01_run_metacheck/res_code_check.RData")
status("Done. Corpus-wide res_*_check.RData files updated with the %d reran papers.", length(rerun_ok))
status("Next: run targets::tar_make() from the project root to rebuild the comparison data, worklist, and manuscript.")
