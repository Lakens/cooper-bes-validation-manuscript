# Saving and reading the corpus-wide result files in parts.
#
# WHY THIS EXISTS
# GitHub's Git LFS accepts at most 2 GB per file. By October 2026,
# res_data_check.RData and res_code_check.RData had each grown to about
# 3.5 GB, so they could no longer be pushed. Almost all of that size is one
# long list in each object, which nothing in the comparison or the manuscript
# reads, but which is worth keeping:
#   - res_data_check$previews: a preview of the content of every downloaded
#     data file (one list element per file: the first rows of each table).
#     Metacheck's codebook_check module reads these to compare a dataset
#     with its documentation.
#   - res_code_check$prev_outputs_by_batch: the repo_check and data_check
#     results that metacheck passes on to code_check, so that a later module
#     can build on them (one list element per batch of papers).
#
# WHAT IT DOES
# save_corpus_result() writes a result as:
#   - a MAIN file, with the same name and the same object name as before
#     (e.g. res_data_check.RData holding `res_data_check`), containing
#     everything except that one long list. Every table the analysis uses is
#     here, so code that only needs the tables can keep calling load().
#   - numbered PART files next to it (res_data_check.part1.RData, .part2, ...),
#     each holding a consecutive run of the long list's elements, cut so that
#     every file stays under the limit.
# The main object records which part files belong to it, in its
# "corpus_parts" attribute. read_corpus_result() reads the main file and its
# parts and joins them back into the complete object.
#
# RULE FOR OTHER CODE
# Code that changes these files and saves them again (the corpus run,
# 01_run_metacheck.R, and the merge script, 14_rerun_papers_without_downloaded_data.R)
# must read them with read_corpus_result() and save them with
# save_corpus_result(). A plain load() followed by save() would keep only
# the main file's content and silently drop the parts.

# Which list is moved into part files, for each result object. Objects not
# listed here (res_repo_check) are small and are saved as one file, as before.
corpus_split_fields <- c(res_data_check = "previews", res_code_check = "prev_outputs_by_batch")

# File name of part i, next to the main file:
# ".../res_data_check.RData" -> ".../res_data_check.part1.RData".
corpus_part_path <- function(path, i) sub("[.]RData$", sprintf(".part%d.RData", i), path)

# obj:   the complete result object (e.g. res_data_check).
# name:  its object name, used inside the main file ("res_data_check").
# path:  where the main file goes.
# max_part_bytes:  the largest file size accepted on disk (just under
#   GitHub's 2 GB, to leave a margin).
# target_part_mem: how much of the list, measured in memory, goes into one
#   part file. Saved files are compressed to roughly a seventh of their size
#   in memory, so 6 GB in memory normally gives a part file of about 1 GB.
#   If a part file still comes out too large, the list is cut again, finer.
save_corpus_result <- function(obj, name, path, max_part_bytes = 1.9e9, target_part_mem = 6e9) {
  # Step 1: find the long list to move out, if this object has one.
  field <- corpus_split_fields[name]
  big <- if (!is.na(field)) obj[[field]] else NULL

  repeat {
    # Step 2: decide where to cut the list. Each element's size in memory is
    # measured; elements are kept in their original order and grouped by
    # where they start in the running total, so each group holds about
    # target_part_mem bytes. Elements are never split themselves.
    chunks <- list()
    if (length(big)) {
      mem <- vapply(big, function(x) as.numeric(utils::object.size(x)), numeric(1))
      start <- c(0, utils::head(cumsum(mem), -1))   # memory before each element
      chunks <- unname(split(seq_along(big), start %/% target_part_mem))
    }

    # Step 3: write each group to its own part file. Each is first written
    # to a temporary file and only then renamed, so an interrupted save never
    # leaves a half-written file under the real name.
    part_files <- vapply(seq_along(chunks), function(i) corpus_part_path(path, i), "")
    sizes <- numeric(0)
    for (i in seq_along(chunks)) {
      part <- big[chunks[[i]]]
      tmp <- paste0(part_files[i], ".tmp")
      save(part, file = tmp)
      sizes[i] <- file.size(tmp)
      stopifnot(file.rename(tmp, part_files[i]))
    }

    # Step 4: check the sizes on disk. If any part is still at or over the
    # limit (its content compressed less well than usual), halve the amount
    # per part and write them all again.
    if (all(sizes < max_part_bytes)) break
    target_part_mem <- target_part_mem / 2
  }

  # Step 5: an earlier save may have used more parts than this one. Remove
  # part files beyond the last one written now, so no stale part is left
  # next to the main file.
  i <- length(chunks) + 1
  while (file.exists(corpus_part_path(path, i))) { file.remove(corpus_part_path(path, i)); i <- i + 1 }

  # Step 6: write the main file: the object without the long list, plus a
  # record of which part files hold it and how many elements it had (so the
  # reader can check nothing is missing). Again written to a temporary file
  # first, checked against the size limit, and only then renamed.
  main <- obj
  if (length(big)) {
    main[[field]] <- NULL
    attr(main, "corpus_parts") <- list(field = unname(field), files = basename(part_files),
                                        n_elements = length(big))
  }
  assign(name, main)
  tmp <- paste0(path, ".tmp")
  save(list = name, file = tmp)
  stopifnot(file.size(tmp) < max_part_bytes, file.rename(tmp, path))
  invisible(c(path, part_files))
}

# path: the main file. name: the object name inside it (by default the file
# name without ".RData"). Returns the complete object, as it was before
# save_corpus_result() split it.
read_corpus_result <- function(path, name = sub("[.]RData$", "", basename(path))) {
  # Step 1: read the main file.
  e <- new.env()
  load(path, envir = e)
  obj <- e[[name]]

  # Step 2: a file saved whole (before this mechanism, or res_repo_check)
  # has no record of parts; it is already complete.
  parts <- attr(obj, "corpus_parts")
  if (is.null(parts)) return(obj)

  # Step 3: read the part files in order and join their elements back into
  # one list, then check the count matches what the main file recorded.
  big <- list()
  for (f in parts$files) {
    pe <- new.env()
    load(file.path(dirname(path), f), envir = pe)
    big <- c(big, pe$part)
  }
  stopifnot(length(big) == parts$n_elements)

  # Step 4: put the list back in its place and remove the record of parts,
  # so the result is the original object.
  obj[[parts$field]] <- big
  attr(obj, "corpus_parts") <- NULL
  obj
}
