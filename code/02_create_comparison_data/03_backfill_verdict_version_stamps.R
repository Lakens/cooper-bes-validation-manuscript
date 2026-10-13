# One-time backfill: give every verdict already in
# disagreement_review_worklist.xlsx the same version stamp the manual audit
# CSVs carry (see R/audit_staleness.R and R/disagreement_worklist.R).
#
# No verdict written before this stamp existed recorded which metacheck
# install it was checked against, so -- exactly as for the audit CSVs'
# older rows -- metacheck_version is left NA, version_is_exact is FALSE,
# and metacheck_version_date is inferred from git history: the date of the
# earliest commit in which that cell already held its current verdict and
# comment. The repository's history was rebuilt on 2026-10-03, so for any
# verdict written before then this date means "no later than 2026-10-03",
# not the day it was written. Every backfilled verdict therefore counts as
# stale until re-checked against the installed metacheck.
#
# Only adds the stamp columns; no verdict or comment is changed. Refuses to
# run if any stamp column already exists, so it cannot overwrite a real
# (exact) stamp written later.
#
# Usage (from the repository root): Rscript code/02_create_comparison_data/03_backfill_verdict_version_stamps.R

xlsx_path <- "code/02_create_comparison_data/disagreement_review_worklist.xlsx"
verdict_cols <- c("data_availability", "data_archive", "data_license",
                  "data_download", "code_archived", "code_download", "any_readme")
stamp_suffixes <- c("_metacheck_version", "_metacheck_version_date", "_version_is_exact")

current <- as.data.frame(openxlsx::read.xlsx(xlsx_path), stringsAsFactors = FALSE)
if (any(paste0(rep(verdict_cols, each = 3), stamp_suffixes) %in% names(current)))
  stop("Stamp columns already present -- backfill has already run.")

commits <- rev(system2("git", c("log", "--format=%H|%ad", "--date=short", "--", xlsx_path), stdout = TRUE))
snap <- lapply(commits, function(cl) {
  sha <- sub("\\|.*", "", cl); f <- tempfile(fileext = ".xlsx")
  system2("git", c("show", paste0(sha, ":", xlsx_path)), stdout = f)
  list(date = sub(".*\\|", "", cl), df = as.data.frame(openxlsx::read.xlsx(f), stringsAsFactors = FALSE))
})

cell <- function(df, rid, col) {
  i <- match(rid, df$row_id)
  if (is.na(i) || !col %in% names(df)) return(NA_character_)
  as.character(df[[col]][i])
}
same <- function(a, b) identical(ifelse(is.na(a), "", trimws(a)), ifelse(is.na(b), "", trimws(b)))

for (col in verdict_cols) {
  vcol <- paste0(col, "_verdict"); ccol <- paste0(col, "_comment")
  ver <- date <- exact <- rep(NA_character_, nrow(current))
  has <- !is.na(current[[vcol]]) & nzchar(trimws(current[[vcol]]))
  for (i in which(has)) {
    rid <- current$row_id[i]
    for (s in snap) {
      if (same(cell(s$df, rid, vcol), current[[vcol]][i]) &&
          same(cell(s$df, rid, ccol), current[[ccol]][i])) { date[i] <- s$date; break }
    }
    exact[i] <- "FALSE"
  }
  current[[paste0(col, "_metacheck_version")]] <- ver
  current[[paste0(col, "_metacheck_version_date")]] <- date
  current[[paste0(col, "_version_is_exact")]] <- exact
  cat(sprintf("%-18s verdicts: %4d  dated: %4d  dates: %s\n", col, sum(has), sum(!is.na(date)),
              paste(names(table(date)), table(date), sep = "=", collapse = " ")))
}

openxlsx::write.xlsx(current, xlsx_path, overwrite = TRUE)
cat("Wrote", xlsx_path, "\n")
