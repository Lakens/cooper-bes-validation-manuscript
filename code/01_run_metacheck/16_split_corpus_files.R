# One-time conversion (2026-10-13): save res_data_check.RData and
# res_code_check.RData in parts, each under GitHub's 2 GB per-file limit.
#
# Why: both files had grown to about 3.5 GB, so they could not be pushed to
# GitHub. How the parts work, and why splitting was chosen over removing the
# large lists, is explained at the top of R/corpus_files.R.
#
# The content does not change: the script checks every element of the split
# list, and the rest of the object, against the original before it finishes.
#
# Usage (from inside code/), one file per run so only one large object is in
# memory at a time (each is about 26 GB once loaded):
#   Rscript 01_run_metacheck/16_split_corpus_files.R data
#   Rscript 01_run_metacheck/16_split_corpus_files.R code

source("../R/corpus_files.R")

# Step 1: which file to convert, from the command line.
part <- commandArgs(TRUE)[1]
stopifnot(part %in% c("data", "code"))
name <- paste0("res_", part, "_check")
path <- sprintf("01_run_metacheck/%s.RData", name)
field <- unname(corpus_split_fields[name])

# Step 2: load the current, whole file. It must not already be split: a
# split main file lacks the long list, and saving it again would lose it.
e <- new.env(); load(path, envir = e); obj <- e[[name]]; rm(e)
stopifnot(is.null(attr(obj, "corpus_parts")))

# Step 3: fingerprint the original before changing anything: one hash per
# element of the long list, and one hash of everything else. Holding the
# original and the read-back copy in memory together would need about 52 GB,
# more than this computer has, so step 5 compares these hashes instead.
element_hashes <- vapply(obj[[field]], rlang::hash, "")
element_names <- names(obj[[field]])
rest_hash <- rlang::hash(obj[setdiff(names(obj), field)])

# Step 4: save it as a main file plus part files (this replaces the whole
# file under the same name), report the file sizes, and free the memory.
files <- save_corpus_result(obj, name, path)
cat(sprintf("%s: %d file(s), %s GB\n", name, length(files),
            paste(sprintf("%.2f", file.size(files) / 1e9), collapse = " + ")))
rm(obj); invisible(gc())

# Step 5: check the saved files against the fingerprints.
#   - the main file: everything except the long list must be unchanged;
#   - the part files, read one at a time: together they must hold every
#     element, in the original order, with the original names and content.
e <- new.env(); load(path, envir = e); main <- e[[name]]; rm(e)
parts <- attr(main, "corpus_parts")
attr(main, "corpus_parts") <- NULL
stopifnot(identical(rlang::hash(main[setdiff(names(main), field)]), rest_hash))
rm(main); invisible(gc())
seen <- 0
for (f in parts$files) {
  pe <- new.env(); load(file.path(dirname(path), f), envir = pe)
  idx <- seen + seq_along(pe$part)
  stopifnot(identical(names(pe$part), element_names[idx]),
            identical(vapply(pe$part, rlang::hash, ""), element_hashes[idx]))
  seen <- seen + length(pe$part)
  rm(pe); invisible(gc())
}
stopifnot(seen == length(element_hashes))
cat("every element and the rest of the object match the original\n")
