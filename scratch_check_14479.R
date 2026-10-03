suppressMessages(library(metacheck))
bes <- readRDS("code/data/bes.rds")
ids_lookup <- vapply(bes, function(x) x$paper_id, character(1))
target <- "10_1111_2041_210x_14479"
idx <- which(ids_lookup == target)
p <- bes[[idx[1]]]
cat("=== p$url ===\n")
print(p$url)
paras <- p$text
hit_pids <- unique(paras$paragraph_id[grepl("figshare|data availab|deposited", paras$text, ignore.case = TRUE)])
for (pid in hit_pids[1:min(3,length(hit_pids))]) {
  txt <- paste(paras$text[paras$paragraph_id == pid], collapse = " ")
  cat("--- para", pid, "---\n", substr(txt,1,400), "\n\n")
}
