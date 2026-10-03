# Step 3 of 3: assembles the three small pieces (repo_metadata,
# extracted in-line here since it's already small; structure_slim and
# code_table_slim, extracted by steps 1 and 2 into temporary .rds
# files) into the one file the manuscript actually reads, then cleans
# up the temporary files.
#
# Usage (from inside code/): Rscript 01_run_metacheck/02c_assemble_manuscript_data_slim.R

status <- function(...) cat(sprintf("[%s] %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), sprintf(...)))

status("loading res_repo_check.RData (small, ~80MB)")
load("01_run_metacheck/res_repo_check.RData")
repo_metadata <- res_repo_check$repo_metadata
rm(res_repo_check)
status("extracted repo_metadata: %d rows", nrow(repo_metadata))

structure_slim <- readRDS("01_run_metacheck/_tmp_structure_slim.rds")
code_table_slim <- readRDS("01_run_metacheck/_tmp_code_table_slim.rds")
status("loaded both temporary slim files: structure_slim %d rows, code_table_slim %d rows",
       nrow(structure_slim), nrow(code_table_slim))

save(repo_metadata, structure_slim, code_table_slim,
     file = "01_run_metacheck/manuscript_data_slim.RData")
status("Saved 01_run_metacheck/manuscript_data_slim.RData (%.1f MB)",
       file.size("01_run_metacheck/manuscript_data_slim.RData") / 1e6)

file.remove("01_run_metacheck/_tmp_structure_slim.rds", "01_run_metacheck/_tmp_code_table_slim.rds")
status("Cleaned up temporary files. Done.")
