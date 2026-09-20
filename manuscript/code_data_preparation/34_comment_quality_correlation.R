# Exploratory analysis: does Metacheck's automated, mechanical comment
# COUNT (comment_lines / code_lines / percentage_comment, from
# code_check()'s per-file table) correlate with Cooper et al.'s
# human-judged comment QUALITY rating (code_annotation_scale, 1-10)?
#
# This is a genuinely different question from the rest of this
# manuscript's comparison: every other construct asks "did Metacheck
# detect the same THING a human coder detected" (a repository, a
# license, a download). This asks whether a cheap, fully automatable
# proxy (how much of the code is comments) tracks a construct Metacheck
# cannot compute at all (whether those comments are actually helpful) --
# i.e., is the human judgment call doing something a line count could
# not already tell us.
#
# Usage: Rscript 34_comment_quality_correlation.R

status <- function(...) cat(sprintf("[%s] %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), sprintf(...)))
source("code_data_preparation/helpers.R")  # for .fix_invalid_utf8() (also redefines status(), equivalent to the version above plus an explicit flush)

# -- Cooper et al.'s code_annotation_scale (1-10, human-judged) -------------
# Same doi -> article_id join 03_recreate_cooper_columns.R uses: Cooper's
# raw CSV has no article_id of its own, only `doi`; ../sample.csv (this
# project's own paper sample) maps doi to the article_id used throughout
# the rest of this pipeline. Read directly from Cooper et al.'s own public
# repository (not mirrored in this project's data/ folder), matching how
# 03_recreate_cooper_columns.R reads the same file.
cooper_raw <- read.csv(
  "https://raw.githubusercontent.com/nhcooper123/reproduce-reuse-recycle/main/data/BES-data-code-hackathon-cleaned_2025-12-01.csv",
  na.strings = "NA", stringsAsFactors = FALSE
)
cooper_raw <- .fix_invalid_utf8(cooper_raw)  # a few cells have invalid UTF-8 bytes, see helpers.R
sampled <- read.csv("../sample.csv", colClasses = "character")
doi_to_article_id <- setNames(sampled$article_id, tolower(sampled$doi))
cooper_raw$article_id <- doi_to_article_id[tolower(cooper_raw$doi)]

cooper_annot <- data.frame(
  article_id = cooper_raw$article_id,
  code_annotation_scale = suppressWarnings(as.numeric(cooper_raw$code_annotation_scale)),
  stringsAsFactors = FALSE
)
cooper_annot <- cooper_annot[!is.na(cooper_annot$article_id), ]
status("Cooper code_annotation_scale coded for %d of %d papers.",
      sum(!is.na(cooper_annot$code_annotation_scale)), nrow(cooper_annot))

# -- Metacheck's per-file comment stats, aggregated to one row per paper ----
load("data/res_code_check.RData")
cf <- res_code_check$table

stopifnot(all(c("paper_id", "comment_lines", "code_lines", "percentage_comment") %in% names(cf)))

has_stats <- !is.na(cf$comment_lines) & !is.na(cf$code_lines)
status("%d of %d code_check rows have real comment/line counts (the rest are files that failed to download or parse).",
      sum(has_stats), nrow(cf))

agg <- aggregate(
  cbind(comment_lines, code_lines) ~ paper_id,
  data = cf[has_stats, ],
  FUN = sum
)
# Weighted (by total code lines), not an average of per-file percentages --
# a 500-line file and a 5-line file should not count equally toward "how
# commented is this paper's code overall".
agg$mc_percentage_comment <- agg$comment_lines / (agg$comment_lines + agg$code_lines)
names(agg)[names(agg) == "comment_lines"] <- "mc_comment_lines"
names(agg)[names(agg) == "code_lines"]    <- "mc_code_lines"

# Files-analysed count per paper (all code_check rows, not just those with
# stats) -- useful context: a paper with 1 tiny file is a much noisier
# comment-percentage estimate than one with 20.
n_files <- aggregate(file_name ~ paper_id, data = cf, FUN = length)
names(n_files)[2] <- "mc_code_files_n"
agg <- merge(agg, n_files, by = "paper_id", all.x = TRUE)

status("Comment-line aggregates computed for %d papers with at least one analysable code file.", nrow(agg))

# -- Join --------------------------------------------------------------------
joined <- merge(cooper_annot, agg, by.x = "article_id", by.y = "paper_id", all = FALSE)
both_coded <- joined[!is.na(joined$code_annotation_scale) & !is.na(joined$mc_percentage_comment), ]
status("Both Cooper's rating and Metacheck's comment stats available for %d papers.", nrow(both_coded))

# -- Correlations --------------------------------------------------------------
cor_pearson  <- cor.test(both_coded$code_annotation_scale, both_coded$mc_percentage_comment, method = "pearson")
cor_spearman <- cor.test(both_coded$code_annotation_scale, both_coded$mc_percentage_comment, method = "spearman")
cor_lines    <- cor.test(both_coded$code_annotation_scale, both_coded$mc_comment_lines, method = "spearman")
cor_codelines_control <- cor.test(both_coded$mc_code_lines, both_coded$mc_percentage_comment, method = "spearman")

status("Pearson r (annotation_scale, %% comments) = %.3f, 95%% CI [%.3f, %.3f], p = %.4f, n = %d",
      cor_pearson$estimate, cor_pearson$conf.int[1], cor_pearson$conf.int[2], cor_pearson$p.value, nrow(both_coded))
status("Spearman rho (annotation_scale, %% comments) = %.3f, p = %.4f", cor_spearman$estimate, cor_spearman$p.value)
status("Spearman rho (annotation_scale, raw comment_lines) = %.3f, p = %.4f", cor_lines$estimate, cor_lines$p.value)
status("Spearman rho (code_lines, %% comments) [checking whether longer codebases are systematically more/less commented] = %.3f, p = %.4f",
      cor_codelines_control$estimate, cor_codelines_control$p.value)

# -- Save for the manuscript --------------------------------------------------
comment_quality <- list(
  n_cooper_coded = sum(!is.na(cooper_annot$code_annotation_scale)),
  n_mc_has_stats = nrow(agg),
  n_both = nrow(both_coded),
  pearson_r = unname(cor_pearson$estimate),
  pearson_ci = cor_pearson$conf.int,
  pearson_p = cor_pearson$p.value,
  spearman_rho = unname(cor_spearman$estimate),
  spearman_p = cor_spearman$p.value,
  spearman_rho_lines = unname(cor_lines$estimate),
  spearman_p_lines = cor_lines$p.value,
  codelines_vs_pct_rho = unname(cor_codelines_control$estimate),
  codelines_vs_pct_p = cor_codelines_control$p.value,
  data = both_coded
)
save(comment_quality, file = "data/comment_quality_correlation.RData")
status("Saved data/comment_quality_correlation.RData")
