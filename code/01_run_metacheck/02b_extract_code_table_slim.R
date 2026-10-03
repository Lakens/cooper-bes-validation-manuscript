# Step 2 of 3 (separate fresh process, same reasoning as step 1):
# extracts only the 2 needed columns from res_code_check$table.
#
# Usage (from inside code/): Rscript 01_run_metacheck/02b_extract_code_table_slim.R

status <- function(...) cat(sprintf("[%s] %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), sprintf(...)))
status("loading res_code_check.RData (~1.9GB)")
load("01_run_metacheck/res_code_check.RData")
status("loaded, extracting 2 columns from table")
code_table_slim <- res_code_check$table[, c("paper_id", "repo_url")]
saveRDS(code_table_slim, "01_run_metacheck/_tmp_code_table_slim.rds")
status("saved _tmp_code_table_slim.rds (%d rows)", nrow(code_table_slim))
