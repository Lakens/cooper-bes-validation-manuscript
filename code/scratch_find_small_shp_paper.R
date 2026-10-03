m <- readRDS("02_create_comparison_data/master_comparison.rds")
load("01_run_metacheck/res_data_check.RData")

shp_paper_ids <- m$article_id[grepl("\\.shp\\b", m$data_format, ignore.case = TRUE) & !is.na(m$data_format)]
struct <- res_data_check$structure
n_files_per_paper <- table(struct$paper_id[struct$paper_id %in% shp_paper_ids])
n_files_per_paper <- sort(n_files_per_paper)
cat("Papers by total file count (smallest first):\n")
print(head(n_files_per_paper, 10))
