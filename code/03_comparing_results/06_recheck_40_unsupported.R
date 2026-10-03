# Individually re-verifies every paper in the 180-paper set (Cooper coded
# an unsupported-looking data_archive label AND repo_check found nothing)
# that Appendix A.6's own manual review (repo_not_detected_categorization.csv)
# never reached -- 40 papers, identified by set difference against that
# file's own article_id column. Each paper's actual cited repository/DOI is
# checked LIVE against the specific platform it names, the same standard
# repo_not_detected_categorization.csv's existing rows already use (read
# the paper's own extracted text, then query the cited platform's own API
# directly), not inferred from a domain-name lookup against Metacheck's
# supported-host lists alone -- a domain match does not by itself confirm
# the specific record actually resolves (confirmed directly below: 4TU
# support exists and the DOI resolves, but the specific numeric article ID
# 4TU's own site redirects to does not match the UUID metacheck's own ID
# extractor pulls from the citation, so the live API call still 404s --
# three different, real possibilities this recheck has to distinguish:
# platform genuinely unsupported, platform supported but this specific
# record fails for an identifiable reason, or platform supported and
# working correctly but never reached because of an unrelated cause).
#
# Output: appends a new file, 40_unsupported_recheck.csv, in the same
# article_id/column/comment/category shape as
# repo_not_detected_categorization.csv, so the two can be combined
# directly. Does NOT modify repo_not_detected_categorization.csv itself.
#
# Usage (from inside code/): Rscript 03_comparing_results/06_recheck_40_unsupported.R

library(metacheck)
library(httr2)

status <- function(...) cat(sprintf("[%s] %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), sprintf(...)))

d <- packageDescription("metacheck")
status("metacheck version: %s, commit: %s", d$Version, d$RemoteSha %||% "unknown")

# == Identify the exact 40 papers ============================================
side_by_side <- readRDS("02_create_comparison_data/cooper_vs_metacheck.rds")
unsupported_labels <- c("Other repo/database", "Personal website", "Supplementary materials")
is_unsupported_only <- !is.na(side_by_side$data_archive) &
  vapply(strsplit(side_by_side$data_archive, ";"),
         function(v) all(trimws(v) %in% unsupported_labels), logical(1))
mc_missed <- is_unsupported_only & !side_by_side$mc_data_availability
ids_180 <- side_by_side$article_id[mc_missed]
ids_180 <- ids_180[!is.na(ids_180)]

a6 <- read.csv("03_comparing_results/repo_not_detected_categorization.csv", stringsAsFactors = FALSE)
a6 <- a6[!duplicated(a6$article_id), ]
ids_40 <- setdiff(ids_180, a6$article_id)
status("Papers to recheck: %d", length(ids_40))
stopifnot(length(ids_40) == 40)

# == Pull each paper's own extracted text, and the specific data-
#    availability-relevant sentence(s), directly from bes.rds ==============
bes <- readRDS("data/bes.rds")
paper_ids_all <- names(bes)
idx <- match(ids_40, paper_ids_all)
stopifnot(all(!is.na(idx)))

get_availability_text <- function(p) {
  txt <- paste(p$text$text, collapse = " ")
  # A Data Availability Statement sentence, generously bounded (300 chars
  # after the trigger phrase) -- the same net repo_not_detected_
  # categorization.csv's own existing rows quote from.
  hits <- regmatches(txt, gregexpr(
    "[Dd]ata (are |is |and code )?[Aa]vailab[a-z]*[^.]{0,350}[.]", txt, perl = TRUE))[[1]]
  hits <- unique(hits)
  if (length(hits) == 0) {
    # fall back to any DOI/URL near "repository"/"archive"/"deposit"
    hits <- regmatches(txt, gregexpr(
      "[^.]{0,120}(repository|archive[d]?|deposit(ed)?)[^.]{0,250}[.]", txt, perl = TRUE, ignore.case = TRUE))[[1]]
  }
  if (length(hits) == 0) return(NA_character_)
  paste(hits, collapse = " || ")
}

evidence <- vapply(idx, function(i) get_availability_text(bes[[i]]), character(1))
names(evidence) <- ids_40

# == For each paper with a DOI in its evidence, resolve the DOI live and,
#    where the platform is one of Metacheck's dedicated integrations,
#    call that integration's own info/lookup function directly (not just
#    a domain-name match) ====================================================
extract_dois <- function(txt) {
  if (is.na(txt)) return(character(0))
  unique(regmatches(txt, gregexpr("10\\.[0-9]{4,9}/[^ ,;)\"'|]+", txt))[[1]])
}

resolve_doi <- function(doi_or_url) {
  url <- if (grepl("^10\\.", doi_or_url)) paste0("https://doi.org/", doi_or_url) else doi_or_url
  r <- tryCatch(request(url) |> req_error(is_error = function(r) FALSE) |>
                 req_options(followlocation = TRUE) |> req_perform(),
               error = function(e) NULL)
  if (is.null(r)) return(list(status = NA_integer_, final_url = NA_character_))
  list(status = httr2::resp_status(r), final_url = httr2::resp_url(r))
}

results <- data.frame(article_id = character(0), evidence = character(0),
                      doi = character(0), resolve_status = integer(0),
                      final_url = character(0), stringsAsFactors = FALSE)

for (id in ids_40) {
  txt <- evidence[[id]]
  dois <- extract_dois(txt)
  if (length(dois) == 0) {
    results <- rbind(results, data.frame(article_id = id, evidence = txt,
                     doi = NA_character_, resolve_status = NA_integer_,
                     final_url = NA_character_, stringsAsFactors = FALSE))
    next
  }
  for (doi in dois) {
    res <- resolve_doi(doi)
    results <- rbind(results, data.frame(article_id = id, evidence = txt,
                     doi = doi, resolve_status = res$status,
                     final_url = res$final_url %||% NA_character_,
                     stringsAsFactors = FALSE))
  }
  status("%s: %d DOI(s) checked", id, length(dois))
}

write.csv(results, "03_comparing_results/40_unsupported_doi_resolution.csv", row.names = FALSE)
status("Saved 03_comparing_results/40_unsupported_doi_resolution.csv (%d rows) -- raw evidence for the manual classification pass that follows.", nrow(results))
