suppressMessages(library(metacheck))
m <- readRDS("02_create_comparison_data/master_comparison.rds")

# Re-check the SAME 150 real .shp files and their real paths against the
# NEW classifier, to see how many now correctly classify as data.
load("01_run_metacheck/res_data_check.RData")
shp_paper_ids <- m$article_id[grepl("\\.shp\\b", m$data_format, ignore.case = TRUE) & !is.na(m$data_format)]
struct <- res_data_check$structure
shp_files <- struct[struct$paper_id %in% shp_paper_ids & grepl("\\.shp$", struct$file_name, ignore.case = TRUE), ]

cat("Total real .shp files (from the ALREADY-DOWNLOADED corpus):", nrow(shp_files), "\n")
cat("OLD data_type breakdown (as saved in res_data_check.RData, built under the OLD metacheck version):\n")
print(table(shp_files$data_type, useNA = "always"))

cat("\nRe-classifying the SAME file_name/file_path pairs with the NEW installed metacheck:\n")
new_type <- metacheck::data_classify_files(shp_files$file_name, shp_files$file_path)
print(table(new_type, useNA = "always"))

cat("\nHow many changed from non-data to data:\n")
changed_to_data <- sum(shp_files$data_type != "data" & new_type == "data", na.rm = TRUE)
cat(changed_to_data, "\n")

# same for tif
tif_paper_ids <- m$article_id[grepl("\\.tif\\b", m$data_format, ignore.case = TRUE) & !is.na(m$data_format)]
tif_files <- struct[struct$paper_id %in% tif_paper_ids & grepl("\\.tiff?$", struct$file_name, ignore.case = TRUE), ]
cat("\n\nTotal real .tif files:", nrow(tif_files), "\n")
cat("OLD breakdown:\n")
print(table(tif_files$data_type, useNA = "always"))
new_type_tif <- metacheck::data_classify_files(tif_files$file_name, tif_files$file_path)
cat("\nNEW breakdown (same files, re-classified):\n")
print(table(new_type_tif, useNA = "always"))
