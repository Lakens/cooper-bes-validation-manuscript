suppressMessages(library(metacheck))
options(metacheck.cache.dir = "data")
cat("commit:", packageDescription("metacheck")$GithubSHA1, "\n\n")

bes <- readRDS("data/bes.rds")
ids_lookup <- vapply(bes, function(x) x$paper_id, character(1))

m <- readRDS("02_create_comparison_data/master_comparison.rds")
shp_paper_ids <- m$article_id[grepl("\\.shp\\b", m$data_format, ignore.case = TRUE) & !is.na(m$data_format)]

# Just rerun 3 of the 29 papers as a real, live test
targets <- head(shp_paper_ids, 3)
idx <- match(targets, ids_lookup)
target_papers <- bes[idx]

cat("Running repo_check...\n")
rc <- module_run(target_papers, "repo_check", osf_license = TRUE, cache = FALSE, skip_on_api_limit = FALSE)
cat("repo_check table rows:", nrow(rc$table), "\n")

cat("Running data_check (this actually downloads files)...\n")
dc <- module_run(rc, "data_check", cache = FALSE, skip_on_api_limit = FALSE)
cat("data_check table rows:", nrow(dc$table), "\n")

shp_rows <- dc$table[grepl("\\.shp$", dc$table$file_name, ignore.case = TRUE), ]
cat("\n.shp rows in data_check$table (this is the REAL, post-download table):\n")
print(shp_rows[, intersect(c("file_name","file_location","data_type"), names(shp_rows))])
