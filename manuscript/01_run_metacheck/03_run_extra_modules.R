# Run the extra, fast modules (beyond Cooper et al.'s 8 archiving
# questions) on the full BES corpus -- matching the additional checks
# demonstrated in the original psychsci manuscript. Kept as a SEPARATE
# script from 01_run_metacheck.R/02_run_open_practices_oddpub.R so it can
# run independently (different output files, same read-only bes.rds
# input, no conflict).
#
# This is a copy of manuscript/build_extra_modules.R from the old
# cooper_validation_metacheck repository, relocated here together with
# its outputs; only the output paths were changed (all now relative to
# this folder instead of data/).
#
# NOTE: as of this copy, manuscript.qmd does not yet cite any results
# from these 8 output files -- they were produced but not yet used in
# the manuscript.
#
# NOTE on the power module: unlike the other 7 modules, it is run WITH
# metacheck's LLM support enabled (llm_use(TRUE), llm_model("groq")),
# since it sends every candidate power-analysis sentence to an LLM for
# classification -- a materially different cost/time profile from the
# other modules. Rerunning this part requires a valid Groq API key
# configured wherever metacheck's llm_use()/llm_model() expect it (see
# metacheck's own documentation); without one this section will fail or
# silently fall back, depending on metacheck's version.
#
# Usage (from inside manuscript/): Rscript 01_run_metacheck/03_run_extra_modules.R
library(metacheck)

bes <- readRDS("data/bes.rds")

OUT_DIR <- "01_run_metacheck"

run_and_save <- function(module_name, extra_args = list()) {
  out <- file.path(OUT_DIR, paste0("res_", module_name, ".RData"))
  if (file.exists(out)) {
    message(module_name, ": already done, skipping")
    return(invisible())
  }
  message(module_name, ": running on ", length(bes), " papers...")
  res <- do.call(module_run, c(list(bes, module_name), extra_args))
  assign(paste0("res_", module_name), res)
  save(list = paste0("res_", module_name), file = out)
  message(module_name, ": done -> ", out)
}

for (m in c("stat_p_exact", "stat_p_nonsig", "stat_effect_size",
            "coi_check", "ethics_check", "funding_check", "prereg_check")) {
  run_and_save(m)
}

# power WITH the LLM enabled -- a materially different cost/time profile
# (sends text to Groq for every candidate power-analysis sentence).
power_out <- file.path(OUT_DIR, "res_power.RData")
if (!file.exists(power_out)) {
  message("power (LLM): running on ", length(bes), " papers...")
  llm_use(TRUE)
  llm_model("groq")
  llm_max_calls(3000)
  res_power <- module_run(bes, "power")
  llm_use(FALSE)
  save(res_power, file = power_out)
  message("power (LLM): done -> ", power_out)
} else {
  message("power (LLM): already done, skipping")
}

message("All extra modules complete.")
