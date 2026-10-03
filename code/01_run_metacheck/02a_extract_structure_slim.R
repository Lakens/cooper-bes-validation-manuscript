# Step 1 of 3 (run in its own fresh Rscript process so the OS fully
# reclaims memory afterward, rather than relying on gc() within a
# single long-lived process): extracts only the 4 needed columns from
# res_data_check$structure and saves them to a small intermediate file.
#
# Usage (from inside code/): Rscript 01_run_metacheck/02a_extract_structure_slim.R

status <- function(...) cat(sprintf("[%s] %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), sprintf(...)))
status("loading res_data_check.RData (~1.9GB)")
load("01_run_metacheck/res_data_check.RData")
status("loaded, extracting 4 columns from structure")
structure_slim <- res_data_check$structure[, c("paper_id", "data_type", "repo_url", "file_name")]
saveRDS(structure_slim, "01_run_metacheck/_tmp_structure_slim.rds")
status("saved _tmp_structure_slim.rds (%d rows)", nrow(structure_slim))
