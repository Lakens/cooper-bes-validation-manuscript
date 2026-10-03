suppressMessages(library(metacheck))
options(metacheck.cache.dir = "data")

# Directly verify the "want" gate logic itself, not a full corpus rerun:
# recreate the exact `want`/`never_fetch` decision data_check.R makes,
# for a .shp file, under OLD vs NEW classification.
old_type <- "unknown"
new_type <- "data"

never_fetch <- c("materials", "unknown")
cat("OLD: would '", old_type, "' survive the never_fetch gate? ", !(old_type %in% never_fetch), "\n", sep = "")
cat("NEW: would '", new_type, "' survive the never_fetch gate? ", !(new_type %in% never_fetch), "\n", sep = "")
