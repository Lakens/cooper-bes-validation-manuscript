# Extracts the small subset of columns the manuscript actually needs from
# the three large (multi-GB) res_*_check.RData files, so manuscript.qmd
# never has to hold a multi-gigabyte object in memory. Originally three
# separate Rscript processes (01_run_metacheck/02a/02b/02c_*.R), run in
# their own fresh processes specifically so the OS reclaimed memory
# between steps; under targets, tar_option_set(memory = "transient",
# garbage_collection = TRUE) in _targets.R achieves the same effect
# within one session, so these are plain functions here.

extract_structure_slim <- function(res_data_check_file) {
  load(res_data_check_file)
  res_data_check$structure[, c("paper_id", "data_type", "repo_url", "file_name")]
}

extract_code_table_slim <- function(res_code_check_file) {
  load(res_code_check_file)
  res_code_check$table[, c("paper_id", "repo_url")]
}

assemble_manuscript_data_slim <- function(res_repo_check_file, structure_slim, code_table_slim) {
  load(res_repo_check_file)
  repo_metadata <- res_repo_check$repo_metadata
  list(
    repo_metadata = repo_metadata,
    structure_slim = structure_slim,
    code_table_slim = code_table_slim
  )
}
