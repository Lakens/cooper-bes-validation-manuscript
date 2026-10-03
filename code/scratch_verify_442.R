suppressMessages(library(metacheck))
cat("commit:", packageDescription("metacheck")$GithubSHA1, "\n\n")

cat("=== Direct function checks (no folder hint) ===\n")
files <- c("voronoi.shp", "shoreline.shp", "sample.dbf", "sample.shx", "sample.prj",
          "sample.gpkg", "sample.nex", "sample.nwk", "sample.tre", "sample.phy",
          "sample.mzxml", "sample.mztab", "sample.ply", "sample.tab", "sample.table",
          "sample.stl")
for (f in files) {
  cat(sprintf("%-20s -> %s\n", f, metacheck::data_classify_files(f, NULL)))
}
