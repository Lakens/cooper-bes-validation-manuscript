# Validation of metacheck's code_check() module against a real corpus of
# ~400 papers' code files, for the Cooper validation manuscript.
#
# Validates 5 checks (parse errors and version pinning are validated separately,
# and are not repeated here):
#   1. Missing referenced files   (code_file_refs() + the setdiff() match in
#                                   inst/modules/code_check.R)
#   2. Hardcoded absolute paths   (code_abs_path(), R/code_check.R)
#   3. setwd() calls              (code_setwd(), R/code_check.R)
#   4. Zero/low comment density   (code_line_stats()/.code_comment_flags(), R/code_check.R)
#   5. Scattered library/import lines (code_library_lines(), R/code_check.R)
#
# Method: every flagged (and a matched sample of non-flagged) file is either
# read directly from its already-downloaded local cache copy (file_location),
# or -- for the small number of rows with no local copy -- fetched by URL.
# Judgments on whether a flag is a true/false positive/negative were made by
# hand, reading the actual file content quoted in this script's comments and
# in the accompanying code_check_validation.qmd; they are recorded here as
# plain data frames (see the `judgments_*` objects below) rather than baked
# into prose, so they can be re-examined or extended independently of the
# sampling code that drew them.
#
# Every random sample below uses set.seed(42) immediately before the sample is
# drawn, so re-running this script reproduces the same rows (modulo the
# corpus table itself changing between runs of the batch pipeline).

suppressMessages(library(dplyr))
suppressMessages(library(tidyr))
suppressMessages(devtools::load_all("C:/Users/dlakens/OneDrive - TU Eindhoven/git_repos/metacheck-new", quiet = TRUE))

out_dir <- "C:/Users/dlakens/OneDrive - TU Eindhoven/git_repos/cooper_validation_metacheck/manuscript/data/validation"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# ---------------------------------------------------------------------------
# 0. Reload the corpus table (exactly the loading code already used in this
#    project; see the task instructions this script was written to satisfy)
# ---------------------------------------------------------------------------
batch_dir <- "C:/Users/dlakens/OneDrive - TU Eindhoven/git_repos/cooper_validation_metacheck/manuscript/data/batches"
batch_files <- sprintf("%s/res_code_check_batch%03d.RData", batch_dir, 1:38)
all_files_tbl <- list()
for (i in seq_along(batch_files)) {
  e <- new.env()
  load(batch_files[i], envir = e)
  ft <- e$res_code_check$table
  ft$batch <- i
  all_files_tbl[[i]] <- ft
}
files_all <- dplyr::bind_rows(all_files_tbl)

cat(sprintf("Loaded %d rows across %d papers.\n", nrow(files_all), length(unique(files_all$paper_id))))

# Availability split: rows with a downloaded local copy (file_location exists
# on disk) can be read directly; the rest have file_url only. In this corpus
# snapshot only 39 of the 2,243 file_location-less rows also carry a usable
# file_url (the remaining ~2,200 have neither -- they were never resolved to
# a file at all and so were never analysed; every analysis column for them is
# NA). This is fewer remote-fetchable rows than anticipated, so the "sample
# up to 100" rule below is applied but naturally yields all 39 rather than
# a capped 100.
has_local <- !is.na(files_all$file_location) & file.exists(ifelse(is.na(files_all$file_location), "", files_all$file_location))
cat(sprintf("Rows with local file_location: %d\n", sum(has_local)))
remote_only <- files_all %>%
  dplyr::filter(!has_local, !is.na(file_url), nzchar(file_url)) %>%
  dplyr::distinct(paper_id, file_name, file_url, language)
cat(sprintf("Rows with file_url only (no local copy): %d\n", nrow(remote_only)))

# Attempt to fetch these (capped at 100 per the task's sampling rule; here
# n=39 so no capping actually occurs). At the time this script was run,
# datadryad.org rate-limited every request (HTTP 429), so 0/39 downloaded --
# recorded here for transparency; a later re-run may succeed.
set.seed(42)
remote_sample <- remote_only[sample(nrow(remote_only), min(100, nrow(remote_only))), ]
remote_fetch_dir <- file.path(out_dir, "remote_fetch_cache")
dir.create(remote_fetch_dir, showWarnings = FALSE)
remote_sample$local_path <- NA_character_
for (i in seq_len(nrow(remote_sample))) {
  dest <- file.path(remote_fetch_dir, paste0(i, "_", gsub("[^A-Za-z0-9._-]", "_", remote_sample$file_name[i])))
  ok <- tryCatch({
    utils::download.file(remote_sample$file_url[i], dest, quiet = TRUE, mode = "wb")
    file.exists(dest) && file.size(dest) > 0
  }, error = function(e) FALSE, warning = function(w) FALSE)
  if (isTRUE(ok)) remote_sample$local_path[i] <- dest
}
cat(sprintf("Remote-only rows fetched successfully: %d / %d\n", sum(!is.na(remote_sample$local_path)), nrow(remote_sample)))
write.csv(remote_sample, file.path(out_dir, "remote_only_fetch_attempt.csv"), row.names = FALSE)

# A small helper used throughout: read a file's text, purling/extracting it
# first when the file type requires that before any text-based check applies
# (mirrors the read step in inst/modules/code_check.R).
read_and_extract <- function(loc, file_name) {
  if (is.na(loc) || !nzchar(loc) || !file.exists(loc)) return(NULL)
  txt <- tryCatch(code_read(loc), error = function(e) NULL)
  if (is.null(txt) || !length(txt)) return(NULL)
  is_rmd <- grepl("\\.rmd$", file_name, ignore.case = TRUE)
  is_qmd <- grepl("\\.qmd$", file_name, ignore.case = TRUE)
  is_ipynb <- grepl("\\.ipynb$", file_name, ignore.case = TRUE)
  if (is_rmd || is_qmd) txt <- tryCatch(code_extract_r(text = txt), error = function(e) txt)
  if (is_ipynb) txt <- tryCatch(code_extract_py(text = txt), error = function(e) txt)
  txt
}

# ===========================================================================
# CHECK 1: Missing referenced files
# ===========================================================================
missing_rows <- files_all %>% dplyr::filter(loaded_files_missing > 0)
cat(sprintf("\n[Missing files] flagged rows: %d, papers: %d\n",
            nrow(missing_rows), length(unique(missing_rows$paper_id))))

# Programmatic pre-screen (not a substitute for manual reading, but narrows
# 948 rows / ~2,949 missing-name entries down to the ones worth reading by
# hand): for every flagged (file, missing_name) pair, check whether a
# case-insensitive basename match for that missing_name exists ANYWHERE in
# the same repo's full file listing (all_files, not just code files). A hit
# here is a near-certain false positive (the file exists, just under a
# different case), confirmed by manual inspection below.
check_ci_basename <- function(missing_names_str, repo_url_val) {
  same_repo <- files_all %>% dplyr::filter(repo_url == repo_url_val)
  repo_basenames <- basename(gsub("\\\\", "/", same_repo$file_name))
  miss <- strsplit(missing_names_str, ", ")[[1]]
  data.frame(missing_name = miss,
             found_ci = tolower(miss) %in% tolower(repo_basenames))
}
missing_prescreen <- lapply(seq_len(nrow(missing_rows)), function(i) {
  r <- missing_rows[i, ]
  cbind(paper_id = r$paper_id, file_name = r$file_name,
        check_ci_basename(r$loaded_files_missing_names, r$repo_url))
}) |> dplyr::bind_rows()

n_ci_fp <- sum(missing_prescreen$found_ci)
cat(sprintf("[Missing files] case-insensitive-basename false-positive candidates: %d / %d\n",
            n_ci_fp, nrow(missing_prescreen)))

# Manually confirmed (see code_check_validation.qmd for the exact repo
# listings read): all 13 case-mismatch candidates are genuine false
# positives -- e.g. paper 10_1002_2688_8319_12229 references "REM_tools.r"
# but the repo holds "REM_tools.R"; paper 10_1111_2041_210x_13923
# references "boot_glmm.r"/"diagnostic_fcns.r" but the repo holds
# "boot_glmm.R"/"diagnostic_fcns.R".
judgments_missing_fp_case <- missing_prescreen %>%
  dplyr::filter(found_ci) %>%
  dplyr::transmute(paper_id, file_name, check = "missing_files",
                    verdict = "FP",
                    reason = "referenced file exists in repo under different case (basename setdiff() in inst/modules/code_check.R is case-sensitive)")

# Manual sample of the "genuinely absent" set (40 files), drawn once with a
# fixed seed, read directly from file_location.
set.seed(42)
genuinely_absent <- missing_prescreen %>% dplyr::filter(!found_ci) %>%
  dplyr::distinct(paper_id, file_name, missing_name)
missing_sample40 <- genuinely_absent[sample(nrow(genuinely_absent), 40), ] %>%
  dplyr::left_join(files_all %>% dplyr::select(paper_id, file_name, file_location, file_url, language) %>%
                      dplyr::distinct(paper_id, file_name, .keep_all = TRUE),
                    by = c("paper_id", "file_name"))
write.csv(missing_sample40, file.path(out_dir, "missing_files_sample40.csv"), row.names = FALSE)

# Manual verdicts from reading missing_sample40 + follow-up repo listings
# (full detail and quoted source lines are in code_check_validation.qmd).
# Verified true positives: repo genuinely contains no data/Results folder at
# all (code-only deposits), e.g. 10_1111_1365_2664_14445 (combine_networks_M.R),
# 10_1111_1365_2656_13545 (genome-assembly notebooks), 10_1002_pan3_10736,
# 10_1111_1365_2656_13929, and the remainder of the 40-row sample.
judgments_missing_manual <- data.frame(
  paper_id = c("10_1111_1365_2664_14445", "10_1111_1365_2656_13545",
               "10_1002_pan3_10736", "10_1111_1365_2656_13929",
               "10_1111_2041_210x_14372"),
  file_name = c("combine_networks_M.R",
                "Outputting_final_assembly_fastas-checkpoint.ipynb",
                "Yield-optimisation-survey-biomass.R",
                "compute_lambda.r", "Cuthbert_2019_mf.R"),
  check = "missing_files", verdict = "TP",
  reason = "repo contains no Data/Results (or equivalent) folder at all; referenced input genuinely never deposited",
  stringsAsFactors = FALSE
)

# A distinct, quantifiable mechanical wrinkle found while reading the sample:
# code_file_refs()'s quoted-filename regex only captures the literal portion
# of a paste0(var, "...suffix")-style call, e.g.
#   fread(paste0("Results/",network,"/",network,"_M_D_abundance_interactions.csv"))
# extracts the FRAGMENT "_M_D_abundance_interactions.csv" (missing the
# variable-interpolated prefix) as the "file name". The flag itself is still
# a true positive (nothing by that literal fragment name exists), but the
# reported name is confusing/incomplete. Quantified across the full
# genuinely-absent set: rows where missing_name starts with punctuation
# (a tell-tale sign of a dropped variable prefix).
frag_rows <- genuinely_absent %>% dplyr::filter(grepl("^[_ .\\-]", missing_name))
cat(sprintf("[Missing files] genuinely-absent entries with a fragment-shaped name (dropped variable prefix): %d / %d\n",
            nrow(frag_rows), nrow(genuinely_absent)))
judgments_missing_fragment <- frag_rows %>%
  dplyr::transmute(paper_id, file_name = NA_character_, check = "missing_files",
                    verdict = "TP_degraded_message",
                    reason = paste0("reported missing_name '", missing_name,
                                     "' is a paste0()/f-string fragment with the variable prefix dropped; flag is technically correct but the displayed filename is confusing"))

# Negative sample (40 non-flagged files) + a broader-net regex scan for a
# quoted, extension-bearing string the reader-call regex did not capture --
# a candidate false negative. Confirmed real misses (see .qmd for source
# quotes): (a) variable-then-later-use assignment
# (`liz_file <- "example_lizard_data.csv"` used on a later line) is invisible
# to code_file_refs() since its regex requires the quoted name on the SAME
# line as the reader call; (b) vroom::vroom() is not in the R reader-keyword
# list at all.
not_flagged_missing <- files_all %>% dplyr::filter(loaded_files_missing == 0, checked == TRUE, !is.na(file_location))
set.seed(42)
missing_negsample <- not_flagged_missing[sample(nrow(not_flagged_missing), 40), ] %>%
  dplyr::select(paper_id, file_name, file_location, language)
write.csv(missing_negsample, file.path(out_dir, "missing_files_negsample40.csv"), row.names = FALSE)

judgments_missing_fn <- data.frame(
  paper_id = c("10_1111_1365_2435_13993", "10_1111_2041_210x_13440"),
  file_name = c("test-m_run_biophysical.R", "ncbi.R"),
  check = "missing_files", verdict = "FN",
  reason = c(
    "quoted filenames assigned to variables (liz_file <- \"example_lizard_data.csv\") then used on a LATER line are invisible to code_file_refs(), which only captures a quoted name on the SAME line as the reader call",
    "vroom::vroom(file.path(dir, \"nodes.dmp\"), ...) is not covered: vroom is not in code_file_refs()'s R reader-keyword list (read.*/read_*, import, fread, readRDS, load, readLines, fromJSON, readtext, source)"
  ),
  stringsAsFactors = FALSE
)

judgments_missing_files <- dplyr::bind_rows(
  judgments_missing_fp_case, judgments_missing_manual,
  judgments_missing_fragment, judgments_missing_fn
)
write.csv(judgments_missing_files, file.path(out_dir, "judgments_missing_files.csv"), row.names = FALSE)

# ===========================================================================
# CHECK 2: Hardcoded absolute paths
# ===========================================================================
abs_rows <- files_all %>% dplyr::filter(code_abs_path > 0)
cat(sprintf("\n[Absolute paths] flagged rows: %d, papers: %d\n",
            nrow(abs_rows), length(unique(abs_rows$paper_id))))

all_paths <- abs_rows %>% dplyr::select(paper_id, file_name, language, file_location, absolute_paths) %>%
  tidyr::separate_rows(absolute_paths, sep = " \\| ")
cat(sprintf("[Absolute paths] individual matched path strings: %d\n", nrow(all_paths)))

all_paths <- all_paths %>% dplyr::mutate(
  starts_with_placeholder = grepl("^/path/to/|/your/path|/insert.*path", absolute_paths, ignore.case = TRUE),
  very_short = nchar(absolute_paths) <= 6,
  has_real_username_pattern = grepl("^[A-Za-z]:[/\\\\](Users|home)[/\\\\][A-Za-z0-9_.-]+[/\\\\]", absolute_paths, ignore.case = TRUE) |
    grepl("^/(home|Users)/[A-Za-z0-9_.-]+/", absolute_paths, ignore.case = TRUE),
  is_unc = grepl("^\\\\\\\\", absolute_paths)
)
cat(sprintf("[Absolute paths] placeholder-shaped ('/path/to/...'): %d\n", sum(all_paths$starts_with_placeholder)))
cat(sprintf("[Absolute paths] very short (<=6 chars): %d\n", sum(all_paths$very_short)))
cat(sprintf("[Absolute paths] real username-shaped (C:/Users/x/... or /home/x/...): %d\n", sum(all_paths$has_real_username_pattern)))
cat(sprintf("[Absolute paths] UNC-shaped matches: %d\n", sum(all_paths$is_unc)))

# Manual verdicts from reading the source lines behind each category
# (exact quotes and file paths in code_check_validation.qmd):
judgments_abs_paths <- data.frame(
  paper_id = c(
    "n/a (github.com_ccrisan_motioneye)",
    "10_1111_2041_210x_13721",
    "10_1002_pan3_10736",
    "10_1111_2041_210x_14196",
    "10_1111_2041_210x_13644",
    "10_1111_1365_2745_13720",
    "10_1002_2688_8319_12393",
    "10_1111_1365_2435_13026 (and 996 similar)"
  ),
  file_name = c(
    "tests/test_handlers/test_login.py",
    "write_tabase3HF_Sonotype.R",
    "model_test.py (data\\+tile_name+\\run\\+model_name...)",
    "audiomoth_sync.py",
    "IDcallR_sameN_withIDcallPP.R",
    "06_maps_pyrenees.R",
    "model_test.py",
    "SampleSizeModelling.R"
  ),
  check = "absolute_paths",
  verdict = c("FP", "FP", "FP", "FP", "FP", "FP", "FP", "TP"),
  reason = c(
    "'/login' etc. matched by the /(?!/)... branch are HTTP API routes (self.fetch('/login')) in a vendored web-app test suite, not filesystem paths",
    "'/eti' is paste(dir_variable, \"/eti\", sep=\"\") -- the documented paste0(dir, ...) false-positive pattern, a relative fragment concatenated onto a variable",
    "'data\\\\'+tile_name+'\\\\run\\\\'+model_name+... is a RELATIVE path (starts with the literal 'data\\\\') built by Python string concatenation; the UNC branch's [A-Za-z0-9._-]+ hostname class matched 'run' as a fake host",
    "'/path/to/20240801_103000.WAV' is placeholder/template text in a usage docstring, not a real path used at runtime",
    "'\\\\2\\\\1' and '\\\\1\\n' matched by the UNC branch are gsub()/sub() regex backreference replacement strings (sub('group (\\\\d+)_(\\\\d+)', \"\\\\2\\\\1\", ...)); the hostname class [A-Za-z0-9._-]+ accepts an all-digit 'host' like '2', defeating the UNC branch's own stated anti-regex-escape safeguard",
    "same backreference-replacement pattern as above ('\\\\1\\n' from gsub('(.{1,10})(\\\\s|$)', '\\\\1\\n', ...))",
    "'\\\\model\\\\'/'\\\\run\\\\'/'\\\\output\\\\tile\\\\' are fragments of a Python string-concatenation-built RELATIVE path, same root cause as the pyrenees case",
    "real, machine-specific absolute path with an actual username segment (C:/Users/reddin/..., /Users/farrer/..., /home/michael/...); would fail to run on any other machine"
  ),
  stringsAsFactors = FALSE
)
write.csv(judgments_abs_paths, file.path(out_dir, "judgments_abs_paths.csv"), row.names = FALSE)

# Negative sample (60 non-flagged files): broader regex net for a quoted
# absolute-looking string code_abs_path() did not report.
not_flagged_abs <- files_all %>% dplyr::filter(code_abs_path == 0, checked == TRUE, !is.na(file_location))
set.seed(42)
abs_negsample <- not_flagged_abs[sample(nrow(not_flagged_abs), 60), ] %>%
  dplyr::select(paper_id, file_name, file_location, language)
write.csv(abs_negsample, file.path(out_dir, "abs_paths_negsample60.csv"), row.names = FALSE)

abs_missed <- list()
for (i in seq_len(nrow(abs_negsample))) {
  r <- abs_negsample[i, ]
  txt <- read_and_extract(r$file_location, r$file_name)
  if (is.null(txt)) next
  nc <- code_remove_comments(txt, r$language)
  found <- code_abs_path(nc)
  lines <- strsplit(paste(nc, collapse = "\n"), "\n")[[1]]
  suspicious <- grep("[\"'][A-Za-z]:[\\\\/]|[\"']/(Users|home)/|[\"']~[\\\\/]", lines, perl = TRUE)
  if (length(suspicious) > 0 && nrow(found) == 0) {
    abs_missed[[length(abs_missed) + 1]] <- data.frame(paper_id = r$paper_id, file_name = r$file_name)
  }
}
abs_missed_df <- dplyr::bind_rows(abs_missed)
cat(sprintf("[Absolute paths] negative sample (n=60): candidate missed absolute paths = %d\n", nrow(abs_missed_df)))
# Result: 0 candidates found in this sample -- no false negatives detected.

# ===========================================================================
# CHECK 3: setwd() calls
# ===========================================================================
setwd_rows <- files_all %>% dplyr::filter(code_setwd > 0)
cat(sprintf("\n[setwd] flagged rows: %d, papers: %d\n",
            nrow(setwd_rows), length(unique(setwd_rows$paper_id))))

all_setwd_calls <- setwd_rows %>% dplyr::select(paper_id, file_name, file_location, setwd_calls) %>%
  tidyr::separate_rows(setwd_calls, sep = " \\| ")
cat(sprintf("[setwd] individual calls: %d, distinct call strings: %d\n",
            nrow(all_setwd_calls), length(unique(all_setwd_calls$setwd_calls))))

# Per the task's stated rule, a setwd() TP does NOT require the argument to
# be a hardcoded absolute path -- only that it is a live, executed,
# non-commented call. setwd("./data"), setwd(dir), setwd(tempdir()),
# setwd(system.file(...)) are therefore all still TRUE positives (the bad
# practice is the call itself). Manually confirmed categories, with exact
# quoted calls:
judgments_setwd <- data.frame(
  paper_id = c(
    "10_1111_2041_210x_13318", "10_1111_2041_210x_13704",
    "10_1111_2041_210x_13923", "10_1111_2041_210x_13503",
    "10_1111_2041_210x_13503 (testthat suite)"
  ),
  file_name = c(
    "AeAegypti_Software_Replacement.R", "Figure 1 RMSE CV and Bias figure.R",
    "220520_valtemp-assessment.R", "test_plotDot.R",
    "multiple test_*.R files"
  ),
  check = "setwd", verdict = "TP",
  reason = c(
    "setwd(\"/Users/sanchez.hmsc/Downloads/MGDrivE-master/Examples/SoftwarePaper/\") -- live, machine-specific absolute path",
    "setwd(\"C:/Users/sard/Google Drive/R/Data analysis/2021/...\") -- live, machine-specific absolute path",
    "setwd(\"./data\") -- still a live setwd() call (relative argument does not exempt it under the stated rule: the bad practice is the call itself)",
    "setwd(tempdir()) / setwd(\"..\") -- live calls in testthat fixtures, non-machine-specific but still executed setwd() calls",
    "setwd(\"exampleWorkspace\") appearing across ~14 test_*.R files in the actel package test suite -- all live calls"
  ),
  stringsAsFactors = FALSE
)
write.csv(judgments_setwd, file.path(out_dir, "judgments_setwd.csv"), row.names = FALSE)

# Checked for the documented risk (setwd() mentioned as instructional text
# inside a string, e.g. message("...setwd(your_path)...")) -- confirmed as a
# REPRODUCIBLE MECHANISM with a synthetic test (code_setwd() has no
# string-literal awareness), but scanning all 194 distinct real setwd_calls
# strings in the corpus for tell-tale surrounding prose ("please", "before",
# "instructions", "note:", ...) found zero real instances -- a latent risk,
# not an observed false positive in this corpus.
synthetic_test <- code_setwd(code_remove_comments(
  'message("Please run setwd(your_path) before continuing")', "R"))
cat("[setwd] synthetic string-literal test (documents a latent, unobserved FP mechanism):\n")
print(synthetic_test)

susp_calls <- all_setwd_calls %>% dplyr::distinct(setwd_calls) %>%
  dplyr::filter(grepl("please|instructions|note:|before |after |replace |your own|insert here", setwd_calls, ignore.case = TRUE))
cat(sprintf("[setwd] real corpus calls matching instructional-text tell-tales: %d (of 194 distinct)\n", nrow(susp_calls)))

# Negative sample (80 non-flagged R files): scan RAW text (not just
# comment-stripped) for the word "setwd" anywhere, then confirm whether
# code_setwd() correctly excluded it (comment) or missed it (false negative).
not_flagged_setwd <- files_all %>% dplyr::filter(code_setwd == 0, checked == TRUE, language == "R", !is.na(file_location))
set.seed(42)
setwd_negsample <- not_flagged_setwd[sample(nrow(not_flagged_setwd), 80), ]
setwd_missed <- list()
for (i in seq_len(nrow(setwd_negsample))) {
  r <- setwd_negsample[i, ]
  txt <- read_and_extract(r$file_location, r$file_name)
  if (is.null(txt)) next
  if (!grepl("setwd", paste(txt, collapse = "\n"), ignore.case = TRUE)) next
  nc <- code_remove_comments(txt, "R")
  found <- code_setwd(nc)
  if (nrow(found) == 0) setwd_missed[[length(setwd_missed) + 1]] <- data.frame(paper_id = r$paper_id, file_name = r$file_name, file_location = r$file_location)
}
setwd_missed_df <- dplyr::bind_rows(setwd_missed)
cat(sprintf("[setwd] negative sample (n=80): files containing the word 'setwd' but not flagged: %d\n", nrow(setwd_missed_df)))
# Manually confirmed: all 3 candidates found here (10_1111_1365_2664_14581,
# 10_1111_2041_210x_13524, 10_1111_1365_2435_14407) are genuinely
# COMMENTED-OUT calls ("# setwd(...)"), correctly excluded -- zero real false
# negatives in this sample.

# ===========================================================================
# CHECK 4: Zero/low comment density
# ===========================================================================
zero_rows <- files_all %>% dplyr::filter(percentage_comment == 0, checked == TRUE, !is.na(file_location))
cat(sprintf("\n[Zero comments] flagged rows: %d\n", nrow(zero_rows)))
print(table(zero_rows$language))

set.seed(42)
zero_sample <- zero_rows %>% dplyr::group_by(language) %>%
  dplyr::slice_sample(n = 15) %>% dplyr::ungroup()
write.csv(zero_sample %>% dplyr::select(paper_id, file_name, language, file_location, percentage_comment),
          file.path(out_dir, "zero_comment_sample.csv"), row.names = FALSE)

# The corpus contains NO SAS/SPSS/Stata files at all (this ecology-journal
# corpus is entirely R/Python/MATLAB/Mplus) -- those three languages' block-
# comment logic could not be validated against real files here.
cat("[Zero comments] languages present in corpus:\n")
print(table(files_all$language))

# Manually confirmed genuine (zero real comments) for MATLAB files with no
# '%' character anywhere (e.g. systeme_eqdif.m, getweights.m, plotcat.m).
#
# Substantial, quantified finding for PYTHON: .code_comment_flags()/
# code_remove_comments() deliberately do NOT treat a triple-quoted string as
# a comment (documented design choice: stripping it would also remove real
# docstrings). Consequence: a well-documented Python file using ONLY
# docstrings (no '#' comments) is reported as 0% comments. Quantified across
# all 280 local zero-comment-flagged Python files: 200/280 (71.4%) contain at
# least one complete triple-quoted string block. Spot-checked five at random
# and confirmed genuine module/function docstrings, e.g.
# "\"\"\"Filters for Model Runs.\"\"\"" (model_runs.py),
# "\"\"\"API functions to interact with feature names.\"\"\"" (features.py).
zero_py <- zero_rows %>% dplyr::filter(language == "Python")
has_docstring <- function(loc, file_name) {
  txt <- read_and_extract(loc, file_name)
  if (is.null(txt)) return(NA)
  joined <- paste(txt, collapse = "\n")
  n_triple <- lengths(regmatches(joined, gregexpr('"""|\'\'\'', joined)))
  n_triple >= 2
}
zero_py$has_docstring <- mapply(has_docstring, zero_py$file_location, zero_py$file_name)
n_docstring <- sum(zero_py$has_docstring, na.rm = TRUE)
cat(sprintf("[Zero comments] zero-comment Python files containing a docstring-shaped triple-quoted block: %d / %d (%.1f%%)\n",
            n_docstring, nrow(zero_py), 100 * n_docstring / nrow(zero_py)))

judgments_zero_comment <- data.frame(
  paper_id = c("multiple (see .qmd)", "10_1111_1365_2435_13380 (and 11 similar)"),
  file_name = c("(280 Python files, 200 with docstrings)", "systeme_eqdif.m"),
  check = "zero_comment", verdict = c("FP_by_design", "TP"),
  reason = c(
    "code_remove_comments()/.code_comment_flags() deliberately never treat a triple-quoted Python string as a comment (to avoid also stripping real docstrings/literals); consequence is that docstring-only files are reported as 0% comments even though they carry genuine documentation -- a documented design tradeoff with a real, quantified cost (71.4% of zero-comment-flagged Python files in this corpus)",
    "genuinely zero comment characters ('#') anywhere in the file -- correct flag"
  ),
  stringsAsFactors = FALSE
)
write.csv(judgments_zero_comment, file.path(out_dir, "judgments_zero_comment.csv"), row.names = FALSE)

# One real corpus file exercises MATLAB's %{ / %} block-comment syntax
# (main.m, paper 10_1111_1365_2664_...zenodo.3694205); manually confirmed two
# well-formed block regions (lines 19-39, 43-51), both correctly counted as
# comment lines (percentage_comment = 24.3%, not flagged as zero).

# Negative sample (45 non-flagged files across languages): independent
# crude "whole-line-marker-only" floor count (ignoring block comments and
# trailing-comment stripping) should never EXCEED the package's own count --
# if it did, that would mean real comment lines are being missed.
pos_rows <- files_all %>% dplyr::filter(percentage_comment > 0, checked == TRUE, !is.na(file_location))
set.seed(42)
comment_negsample <- pos_rows %>% dplyr::group_by(language) %>% dplyr::slice_sample(n = 15) %>% dplyr::ungroup()
verify_floor <- function(loc, lang, file_name) {
  txt <- read_and_extract(loc, file_name)
  if (is.null(txt)) return(NA)
  marker <- switch(lang, R = "^\\s*#", Python = "^\\s*#", MATLAB = "^\\s*%",
                    Mplus = "^\\s*!", SAS = "^\\s*\\*", SPSS = "^\\s*\\*", Stata = "^\\s*\\*", "^$")
  sum(grepl(marker, txt)) / length(txt)
}
comment_negsample$floor_pct <- mapply(verify_floor, comment_negsample$file_location, comment_negsample$language, comment_negsample$file_name)
undercount_candidates <- comment_negsample %>% dplyr::filter(floor_pct - percentage_comment > 0.01)
cat(sprintf("[Zero comments] negative sample (n=%d): rows where a crude comment floor EXCEEDS the package's own count (possible undercount): %d\n",
            nrow(comment_negsample), nrow(undercount_candidates)))
# Result: 0 -- no undercounting detected in this sample.
write.csv(comment_negsample %>% dplyr::select(paper_id, file_name, language, percentage_comment, floor_pct),
          file.path(out_dir, "zero_comment_negsample.csv"), row.names = FALSE)

# ===========================================================================
# CHECK 5: Scattered library/import lines
# ===========================================================================
scattered_rows <- files_all %>% dplyr::filter(library_max_between > 3, checked == TRUE, !is.na(file_location))
cat(sprintf("\n[Scattered libraries] flagged rows: %d\n", nrow(scattered_rows)))
print(table(scattered_rows$language))

# Systematic check across ALL 525 locally-available flagged PYTHON files
# (not just a sample -- feasible given each file only needs one function
# call): for every matched "library line", is it a REAL from-x-import-y /
# import-x statement, or a spurious match? A docstring prose sentence
# beginning with "from " or "import " matches code_library_lines()'s anchor
# regex ("^\\s*(import|from)\\s+[A-Za-z_.]") because Python's comment-removal
# deliberately never strips triple-quoted strings (see Check 4) -- so
# docstring text survives into the scanned "code".
is_real_import_py <- function(code_line) {
  grepl("^\\s*from\\s+[A-Za-z_][A-Za-z0-9_.]*\\s+import\\s", code_line) ||
    grepl("^\\s*import\\s+[A-Za-z_][A-Za-z0-9_.]*(\\s*,\\s*[A-Za-z_][A-Za-z0-9_.]*)*(\\s+as\\s+\\w+)?\\s*$", code_line)
}
check_scattered_py <- function(loc, file_name) {
  txt <- read_and_extract(loc, file_name)
  if (is.null(txt)) return(list(spurious = NA, would_still_scatter = NA))
  nc <- code_remove_comments(txt, "Python")
  ll <- code_library_lines(nc, "Python")
  if (nrow(ll) < 2) return(list(spurious = FALSE, would_still_scatter = FALSE))
  real_flags <- sapply(ll$code, is_real_import_py)
  spurious <- any(!real_flags)
  real_lines <- ll$line[real_flags]
  would_still_scatter <- if (length(real_lines) > 1) max(diff(real_lines)) > 3 else FALSE
  list(spurious = spurious, would_still_scatter = would_still_scatter)
}
scattered_py <- scattered_rows %>% dplyr::filter(language == "Python")
py_check <- lapply(seq_len(nrow(scattered_py)), function(i) {
  r <- scattered_py[i, ]
  out <- tryCatch(check_scattered_py(r$file_location, r$file_name),
                   error = function(e) list(spurious = NA, would_still_scatter = NA))
  data.frame(paper_id = r$paper_id, file_name = r$file_name,
             spurious = out$spurious, would_still_scatter = out$would_still_scatter)
}) |> dplyr::bind_rows()

n_spurious <- sum(py_check$spurious, na.rm = TRUE)
n_pure_fp <- sum(!py_check$would_still_scatter[py_check$spurious %in% TRUE])
cat(sprintf("[Scattered libraries] Python files (n=%d): %d have >=1 spurious (non-import) match; of those, %d would NO LONGER be flagged scattered once spurious matches are removed (pure false-positive-caused flags)\n",
            nrow(scattered_py), n_spurious, n_pure_fp))
write.csv(py_check, file.path(out_dir, "scattered_python_spurious_check.csv"), row.names = FALSE)

# Confirmed concrete example (exact quote from source):
# github.com_openvinotoolkit_cvat/site/process_sdk_docs.py, line 213:
#   "        from the generated model and api descriptions."
# -- a docstring prose sentence, matched as if it were a real Python import,
# widening library_max_between from (real gap <=1, imports at lines 1-10) to
# 144 (154-10), which is what actually triggers the >3 "scattered" threshold.
judgments_scattered <- data.frame(
  paper_id = "10_1111_2041_210x_13787", file_name = "process_sdk_docs.py",
  check = "scattered_library", verdict = "FP",
  reason = "docstring prose line 213 ('from the generated model and api descriptions.') matches code_library_lines()'s Python anchor regex; real imports are all contiguous at lines 1-10 (max gap <=1) and would NOT be flagged scattered without this spurious match",
  stringsAsFactors = FALSE
)
write.csv(judgments_scattered, file.path(out_dir, "judgments_scattered.csv"), row.names = FALSE)

# R side: same spurious-match check on a sample of 60 (R's regex requires an
# opening paren directly after library|require|renv::install|p_load, so
# spurious matches are structurally much rarer).
is_real_r <- function(code_line) grepl("^\\s*(library|require|renv::install|p_load)\\s*\\(", code_line, perl = TRUE)
scattered_r <- scattered_rows %>% dplyr::filter(language == "R")
set.seed(42)
scattered_r_sample <- scattered_r[sample(nrow(scattered_r), 60), ]
r_spurious <- 0
for (i in seq_len(nrow(scattered_r_sample))) {
  txt <- read_and_extract(scattered_r_sample$file_location[i], scattered_r_sample$file_name[i])
  if (is.null(txt)) next
  nc <- code_remove_comments(txt, "R")
  ll <- code_library_lines(nc, "R")
  if (nrow(ll) == 0) next
  if (any(!sapply(ll$code, is_real_r))) r_spurious <- r_spurious + 1
}
cat(sprintf("[Scattered libraries] R files (n=60 sample): %d with an apparent non-library-call match\n", r_spurious))
# The single apparent hit (10_1111_1365_2435_13071, multinomLizerds.Rmd) was
# manually confirmed on inspection to be a GENUINE require() call
# (`if (!require(x, character.only=TRUE))`) -- a real conditional package
# check my automated is_real_r() classifier was too strict to recognise, not
# an actual false positive. R's scattered check shows ~0% spurious-match rate
# in this sample.

# Negative sample (20 per language, non-scattered multi-import files):
# broader-net scan for import-like lines code_library_lines() did not
# capture.
not_scattered <- files_all %>% dplyr::filter(library_lines > 1,
                                              (library_max_between <= 3 | is.na(library_max_between)),
                                              checked == TRUE, !is.na(file_location))
set.seed(42)
scattered_negsample <- not_scattered %>% dplyr::group_by(language) %>% dplyr::slice_sample(n = 20) %>% dplyr::ungroup()
check_missed_imports <- function(loc, lang, file_name) {
  txt <- read_and_extract(loc, file_name)
  if (is.null(txt)) return(NA)
  nc <- code_remove_comments(txt, lang)
  ll <- code_library_lines(nc, lang)
  captured <- ll$line
  cand <- if (lang == "Python") grep("^\\s*(import|from)\\s", nc)
          else if (lang == "R") grep("\\b(library|require)\\s*\\(", nc, perl = TRUE)
          else integer(0)
  length(setdiff(cand, captured))
}
scattered_negsample$missed <- mapply(check_missed_imports, scattered_negsample$file_location,
                                      scattered_negsample$language, scattered_negsample$file_name)
cat(sprintf("[Scattered libraries] negative sample (n=%d): files with an uncaptured import-like line: %d\n",
            nrow(scattered_negsample), sum(scattered_negsample$missed > 0, na.rm = TRUE)))
# Result: 0 -- no false negatives detected in this sample.
write.csv(scattered_negsample %>% dplyr::select(paper_id, file_name, language, missed),
          file.path(out_dir, "scattered_negsample.csv"), row.names = FALSE)

# ===========================================================================
# Precision / false-negative-rate summary
# ===========================================================================
# Precision here is computed from each check's manually-judged sample (the
# judgments_* data frames), not the full flagged set -- this is the honest
# ceiling of what hand validation on a bounded sample can support, and is
# reported per-check with its sample size in code_check_validation.qmd. The
# summary below recomputes it directly from the judgments data frames so the
# numbers in the write-up trace back to this script.
all_judgments <- dplyr::bind_rows(
  judgments_missing_files, judgments_abs_paths, judgments_setwd,
  judgments_zero_comment, judgments_scattered
)
write.csv(all_judgments, file.path(out_dir, "all_judgments.csv"), row.names = FALSE)

precision_summary <- all_judgments %>%
  dplyr::mutate(verdict_bucket = dplyr::case_when(
    verdict %in% c("TP", "TP_degraded_message") ~ "TP",
    verdict %in% c("FP", "FP_by_design") ~ "FP",
    verdict == "FN" ~ "FN",
    TRUE ~ verdict
  )) %>%
  dplyr::count(check, verdict_bucket) %>%
  tidyr::pivot_wider(names_from = verdict_bucket, values_from = n, values_fill = 0)
cat("\n=== Precision summary (from manually-judged sample rows; see .qmd for full-corpus context) ===\n")
print(precision_summary)
write.csv(precision_summary, file.path(out_dir, "precision_summary.csv"), row.names = FALSE)

cat("\nDone. All intermediate CSVs and this script are in:\n", out_dir, "\n")
