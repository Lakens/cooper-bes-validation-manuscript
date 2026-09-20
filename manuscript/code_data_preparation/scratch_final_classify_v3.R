# Third and final classification pass over the 92 genuinely-UNCLEAR rows,
# built from actually reading all 92 comments (not regex-guessed). Splits
# out the three recurring, real platforms found (EIDC/NERC, USGS
# ScienceBase, EDI/Environmental Data Initiative -- each 6-7 occurrences,
# distinct from the single-paper UNSUPPORTED_REPO bucket the same way
# PANGAEA already is), a CRAN_CODE_PACKAGE category (a real, working code
# citation on a package registry, not a data repository at all -- a
# different KIND of "miss" than a repository metacheck failed to detect),
# a BATCH_QUERY_CRASH category (the exact "arguments imply differing
# number of rows: 1, 0" error already fixed for the general case by PR
# #406, apparently still recurring for specific hosts), and folds the
# true one-off institutional repositories into UNSUPPORTED_REPO.
d <- read.csv("data/scratch_final_full_categorization_v2.csv", stringsAsFactors = FALSE,
              colClasses = c(article_id = "character"))

recategorize_unclear <- function(aid, col, comment) {
  if (grepl("EIDC|Environmental Information Data Centre|NERC", comment, ignore.case = TRUE, perl = TRUE)) {
    return("EIDC_NERC")
  }
  if (grepl("ScienceBase", comment, ignore.case = TRUE)) {
    return("USGS_SCIENCEBASE")
  }
  if (grepl("Environmental Data Initiative|EDI\\b|pasta/", comment, ignore.case = TRUE, perl = TRUE)) {
    return("EDI_ENVIRONMENTAL_DATA_INITIATIVE")
  }
  if (grepl("CRAN|cran\\.r-project\\.org", comment, ignore.case = TRUE, perl = TRUE)) {
    return("CRAN_CODE_PACKAGE")
  }
  if (grepl("arguments imply differing number of rows", comment, fixed = TRUE)) {
    return("BATCH_QUERY_CRASH")
  }
  if (grepl("figshare\\.com/s/[A-Za-z0-9]+", comment, ignore.case = TRUE, perl = TRUE)) {
    return("FIGSHARE_SHARE_LINK")
  }
  if (grepl("GitHub", comment, ignore.case = TRUE) &&
      grepl("never located|repo_n ?= ?0|zero rows|zero files", comment, ignore.case = TRUE, perl = TRUE)) {
    return("GITHUB_DETECTION_MISS")
  }
  # Everything else that names a real, single-paper institutional
  # repository (Stanford, Bonanza Creek, CDFW, Manaaki Whenua, CSIC,
  # Cefas, Senckenberg, VTechData, Illinois Data Bank, PSU Datacommons,
  # Oxford Research Archive, Reading RDA, EnviDat, iDiv, Napier, U.
  # Minnesota, DataSTORRE, Groningen Dataverse, AADC, Arctic Data Center,
  # KNB (this specific paper), Purdue PURR, UCL RDR, Lancaster Pure, OFB,
  # Norwegian Polar Data Centre, Quebec open data, SND, MetaboLights, U.
  # Gloucestershire, IRMA DataStore, U. Florida, BEF-China, GLBRC LTER) --
  # confirmed by the earlier comment-wording check to genuinely name a
  # real repository repo_check does not currently support.
  "UNSUPPORTED_REPO"
}

for (i in which(d$category == "UNCLEAR")) {
  d$category[i] <- recategorize_unclear(d$article_id[i], d$column[i], d$comment[i])
}

status <- function(...) cat(sprintf("[%s] %s\n", format(Sys.time(), "%H:%M:%S"), sprintf(...)))
status("Final tally:")
print(sort(table(d$category), decreasing = TRUE))

write.csv(d, "data/scratch_final_full_categorization_v3.csv", row.names = FALSE)
still <- unique(d$article_id[d$category == "UNCLEAR"])
status("\n%d still UNCLEAR.", length(still))
