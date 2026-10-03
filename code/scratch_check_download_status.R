m <- readRDS("02_create_comparison_data/master_comparison.rds")
load("01_run_metacheck/res_data_check.RData")

shp_paper_ids <- m$article_id[grepl("\\.shp\\b", m$data_format, ignore.case = TRUE) & !is.na(m$data_format)]
struct <- res_data_check$structure
shp_files <- struct[struct$paper_id %in% shp_paper_ids & grepl("\\.shp$", struct$file_name, ignore.case = TRUE), ]

cat("Columns available:", paste(names(shp_files), collapse=", "), "\n\n")

cat("file_location populated (non-NA/non-empty), split by OLD data_type:\n")
has_location <- !is.na(shp_files$file_location) & nzchar(shp_files$file_location %||% "")
print(tapply(has_location, shp_files$data_type, sum))
print(tapply(has_location, shp_files$data_type, length))
