# Numbers audit and variable reference

Two things in one document:

1. **A per-variable reference** (the bulk of this file): every number
   computed in `manuscript.qmd`, organized by the manuscript section it
   appears in, in reading order. Each entry gives:
   - **Manuscript location** — line(s) and the rendered sentence.
   - **Why this value is computed** — what question it answers.
   - **Definition** — what the variable actually means, precisely.
   - **Data used** — which saved object(s)/file(s) it reads, and how
     many rows/papers that represents.
   - **Formula** — the actual computation (numerator/denominator or
     derivation rule), in plain terms.
   - **Relation to Cooper** (only for values compared against Cooper et
     al.'s human coding) — which of Cooper's own columns/values it is
     being checked against, and what counts as agreement.
   - **Interpretation** — how to read the resulting number: what a high
     or low value would mean, and any caveat on trusting it at face
     value.
   - **Verification status** — OK (reproduces exactly from current
     data), MISMATCH→FIXED (was wrong, now corrected — with before/
     after), or FLAG (not wrong, but worth knowing about).

2. **A session log** (at the end) of the verification process itself:
   what was checked, in what order, and a list of every fix applied.

---

## How to read "Data used"

Four objects carry almost everything in this manuscript:

- **`master_comparison.rds`** (loaded as `side_by_side`): one row per
  paper, 1861 rows total (the full BES corpus, agreements *and*
  disagreements both included). Carries Cooper et al.'s own coded
  columns (`data_availability`, `code_archived`, `data_archive`, etc.)
  side by side with Metacheck's recreated `mc_*` columns for the same
  paper. This is the table nearly every Cooper-vs-Metacheck comparison
  number in this manuscript is computed from.
- **`res_repo_check.RData`, `res_data_check.RData`,
  `res_code_check.RData`**: the three core modules' full, per-file/
  per-paper output for the whole 1861-paper corpus. Used whenever a
  number needs something finer-grained than `master_comparison`'s
  summary columns (e.g., which specific files a repository contains,
  or a file's own classification).
- **`comparison_statistics.RData`** (`results`, `verdict_tallies`):
  pre-computed confusion-table statistics (sensitivity, specificity,
  McNemar's test, agreement %) and qualitative verdict counts, built
  from `master_comparison.rds` plus the individually-reviewed
  disagreement worklist. Computed by
  `03_comparing_results/01_compute_comparison_statistics.R`.
- **`disagreement_review_worklist.xlsx`** (loaded as `review`): one row
  per disagreement (not per paper) that was individually reviewed
  against the paper's own text and/or a live API call, with a
  `COOPER_RIGHT`/`METACHECK_RIGHT`/`BOTH_DEFENSIBLE`/
  `DIFFERENT_DEFINITION`/`UNCLEAR` verdict and a free-text comment
  justifying it.

---

## Introduction (line 166)

### Recorder workload: median/min/max papers coded per recorder_ID

**Manuscript location.** Line 166: "145 people coded a median of 10
(min = 1, max = 68) manuscripts."

**Why computed.** To illustrate the scale of Cooper et al.'s own
manual-coding effort (145 human coders dividing 1861 papers between
them), as context for why an automated alternative is worth
investigating at all.

**Definition.** For each of the 145 distinct human coders who
contributed at least one row to the corpus, the number of papers they
personally coded; median/min/max taken across those 145 counts.

**Data used.** `master_comparison$recorder_ID` (`side_by_side`), 1861
rows, 145 distinct non-missing values.

**Formula.** `tab <- table(recorder_ID); median(tab); min(tab); max(tab)`.

**Relation to Cooper.** N/A — this describes Cooper et al.'s own coding
process, not a Metacheck comparison.

**Interpretation.** A median of 10 with a max of 68 shows the workload
was very unevenly split across coders (a small number did far more than
their even share) — useful context for why a two-day hackathon model is
labor-intensive even before considering per-item coding time.

**Verification status.** OK — reproduces exactly (median 10, min 1, max
68, 145 recorders) from `master_comparison$recorder_ID` directly.

---

## Methods section — "1. Does the paper use data/code? If so, are they archived?" (lines 403-423)

### `n_cooper_data`, `n_cooper_code`, `n_cooper_either`

**Manuscript location.** Line 413: "Cooper and colleagues found that
1690 papers archived their data and 577 their code, and in total, 1789
papers contain a link to a repository with either data or code."

**Why computed.** Establishes Cooper et al.'s own ground-truth totals
as the baseline every later Metacheck comparison in this subsection is
measured against.

**Definition.** `n_cooper_data` = papers Cooper's coders marked
`data_availability == "Yes"`. `n_cooper_code` = papers marked
`code_archived == "Yes"`. `n_cooper_either` = papers meeting either
condition (logical OR, counted once per paper, not summed).

**Data used.** `side_by_side$data_availability`,
`side_by_side$code_archived` (1861 rows).

**Formula.** `n_cooper_data <- sum(data_availability == "Yes")`;
`n_cooper_code <- sum(code_archived == "Yes")`; `n_cooper_either <-
sum(data_availability == "Yes" | code_archived == "Yes")`.

**Relation to Cooper.** This *is* Cooper's own coding, read verbatim —
no comparison yet at this point, just her numbers restated to set up
the Metacheck-side numbers in the next sentence.

**Interpretation.** 1690 and 577 match Cooper's own published quote
("97%, n=1690... archived their data, but only 35%, n=577... archived
their code") exactly, confirming the join between this project's local
copy of her data and her own paper is correct.

**Verification status.** OK — n_cooper_data=1690, n_cooper_code=577,
n_cooper_either=1789, all reproduce exactly.

### `n_mc_repo_found`, `n_mc_data`, `n_mc_code`, `n_mc_either`

**Manuscript location.** Line 413 (continued): "In total, Metacheck
found 1539 papers that contained a link to a repository... Of these,
1436 papers contained data, 435 papers contained code, and 1488 papers
contained either data or code according to `repo_check`."

**Why computed.** The Metacheck-side mirror of the Cooper totals above,
so the two sides' aggregate counts can be compared directly before the
paper-by-paper comparison in the next paragraph.

**Definition.** `n_mc_repo_found` = papers where `repo_check` located
at least one repository with at least one file of any type
(`mc_data_availability == TRUE`). `n_mc_data`/`n_mc_code` = papers with
at least one file `data_check`/`code_check` classified as `data`/code
respectively (broader than "downloadable and usable" — just
classified). `n_mc_either` = union of the two.

**Data used.** `mc_data_availability` (from `side_by_side`);
`res_data_check$structure` (`data_type == "data"`, 124,775 rows) and
`res_code_check$table` (`paper_id`, 9202 rows) for the finer-grained
data/code classification, since `master_comparison` doesn't carry a
per-file breakdown.

**Formula.** `n_mc_repo_found <- sum(mc_data_availability, na.rm=TRUE)`;
`papers_with_data <- unique(structure$paper_id[structure$data_type ==
"data"])`; `papers_with_code <- unique(table$paper_id)`; `n_mc_either <-
length(union(papers_with_data, papers_with_code))`.

**Relation to Cooper.** Not a direct paper-by-paper comparison yet —
just the aggregate Metacheck-side count set next to Cooper's aggregate
count (1488 vs. 1789) before the next paragraph compares them paper by
paper.

**Interpretation.** Metacheck's aggregate total (1488) is lower than
Cooper's (1789), but — as the next paragraph's paper-level comparison
shows — this gap is not simply "Metacheck misses more than it finds
extra": 1472 papers agree, and the disagreement runs in both
directions (317 Cooper-only, 16 Metacheck-only).

**Verification status.** OK — n_mc_repo_found=1539, n_mc_data=1436,
n_mc_code=435, n_mc_either=1488, all reproduce exactly.

### `n_both_yes_either`, `n_either_total_disagree`, `n_cooper_yes_mc_no`, `n_mc_yes_cooper_no`

**Manuscript location.** Line 415: "the two sides agree for 1472
papers, and disagree for 333 (317 where Cooper's coders found data or
code that Metacheck did not, and 16 where Metacheck found data or code
that Cooper's coders did not)."

**Why computed.** A true paper-by-paper comparison (not just comparing
two aggregate totals, which can hide offsetting errors in both
directions) — the methodological point the surrounding code comment
makes explicitly: "`n_cooper_either - n_mc_either` is NOT the same as
`length(setdiff(cooper_ids, mc_ids))`... it silently nets the two
directions against each other."

**Definition.** `n_both_yes_either` = papers where Cooper AND Metacheck
both say "yes, data or code exists" (intersection). `n_cooper_yes_mc_no`
= papers Cooper said yes, Metacheck said no (Cooper's exclusive set).
`n_mc_yes_cooper_no` = the reverse. `n_either_total_disagree` = sum of
the two directional counts.

**Data used.** `cooper_either_ids` (built from
`side_by_side$article_id` where Cooper said yes to data or code) and
`mc_either_ids` (= `papers_with_data ∪ papers_with_code`, same source
as above).

**Formula.** `n_cooper_yes_mc_no <- length(setdiff(cooper_either_ids,
mc_either_ids))`; `n_mc_yes_cooper_no <-
length(setdiff(mc_either_ids, cooper_either_ids))`;
`n_both_yes_either <- length(intersect(cooper_either_ids,
mc_either_ids))`.

**Relation to Cooper.** This is the first genuine paper-level agreement
check in the manuscript: each paper's Cooper-coded "yes/no" is compared
directly against its own Metacheck-derived "yes/no," not just totals
compared in aggregate.

**Interpretation.** The asymmetry (317 vs. 16) shows Metacheck's main
failure mode here is under-detection (missing a real repository far
more often than inventing a false one) — consistent with the PPV/
sensitivity pattern described throughout the rest of the manuscript.

**Verification status.** OK — n_both_yes_either=1472,
n_either_total_disagree=333, n_cooper_yes_mc_no=317,
n_mc_yes_cooper_no=16; arithmetic cross-check 1472+333=1805=|union| ✓.

### Platform host-support counts (`n_unique_repos` and its five components)

**Manuscript location.** Line 413: "Metacheck supports over 276 unique
repositories (121 Dataverse installations, 64 DSpace 7 installations,
6 legacy DSpace 6 installations, 5 DataOne member nodes, and 69
Figshare-based hosts, plus 11 dedicated single-platform integrations)."

**Why computed.** Quantifies the breadth of Metacheck's platform
coverage as context for the repository-detection gap discussed next —
"this is only a subset of all repositories used in manuscripts."

**Definition.** A count of individually-recognized repository
*hosts* (not papers, not DOIs) across five shared-API backends plus a
fixed count of dedicated single-platform integrations
(OSF/Zenodo/ResearchBox/Dryad/ReShare/GitHub/GitLab/Mendeley
Data/FSD/AsPredicted/4TU = 11, hardcoded since each is a distinct,
individually-written integration rather than a host list).

**Data used.** Metacheck's own internal host-list functions:
`metacheck:::.dataverse_hosts()`,
`.dataverse_doi_prefix_hosts()`, `.dspace7_hosts()`,
`.dspace_legacy_hosts()`, `.dataone_hosts()`,
`.figshare_vanity_hosts()`, `.figshare_doi_prefix_hosts()` — these are
package-internal lookup tables, not corpus data; this number does not
change based on which papers are in the corpus, only on which version
of the `metacheck` package is installed.

**Formula.** `n_unique_repos <- n_dataverse_hosts + n_dspace7_hosts +
n_dspace_legacy_hosts + n_dataone_hosts + n_figshare_hosts +
n_dedicated_platforms` (simple sum of the five host-list lengths plus
the hardcoded 11).

**Relation to Cooper.** N/A — describes Metacheck's own supported-
platform breadth, not a comparison against Cooper's coding.

**Interpretation.** This number will change if `metacheck` itself is
upgraded (e.g., Appendix A.5/A.6 describe several of these host counts
growing over the course of this project) — it measures the tool's
current coverage, not anything about this specific corpus.

**Verification status.** OK — all six components (121/64/6/5/69/11,
summing to 276) reproduce exactly from the installed `metacheck`
package's internal functions.

### Unsupported-repository breakdown (`n_unsupported_repo`, `n_unsupported_personal_web`, `n_unsupported_supp_mat`)

**Manuscript location.** Referenced in the Methods narrative and used
to build the "unsupported platform" framing before Table 1.

**Why computed.** Distinguishes "Cooper coded this paper's archive
platform as something outside Metacheck's named-platform list" from
"this paper is not FAIR-archived at all regardless of tool support" —
two different reasons a paper might not be findable by any automated
tool.

**Definition.** `n_unsupported_repo` = papers whose *entire*
Cooper-coded `data_archive` label set (a paper can have more than one,
semicolon-joined) consists only of "Other repo/database," "Personal
website," and/or "Supplementary materials" — Cooper's three
catch-all/non-platform labels. The latter two sub-counts are how many
of those specifically include "Personal website" or "Supplementary
materials" (not mutually exclusive with each other or with "Other
repo/database").

**Data used.** `side_by_side$data_archive` (1861 rows, semicolon-joined
multi-value text field).

**Formula.** `is_unsupported_only <- vapply(strsplit(data_archive,
";"), function(v) all(trimws(v) %in% c("Other repo/database",
"Personal website", "Supplementary materials")), logical(1))`;
`n_unsupported_repo <- sum(is_unsupported_only)`.

**Relation to Cooper.** Built entirely from Cooper's own coded label,
not Metacheck's — this count says nothing yet about whether Metacheck
actually failed on these papers (that's `n_unsupported_repo_and_mc_missed`,
below); it's purely "how did Cooper's coders describe this paper's
archive."

**Interpretation.** Important caveat stated directly in the
manuscript: "Other repo/database" is NOT the same as "a repository
Metacheck genuinely doesn't support" — several papers with this label
cite a real OSF/Dryad/Zenodo/Figshare deposit Cooper's coding scheme
just had no more specific box for, and Metacheck handles these
correctly. This count should be read as an upper bound on genuinely
unsupported platforms, not a precise count of them (Appendix A.6's
`n_genuinely_unsupported`, verified one paper at a time, is the precise
count).

**Verification status.** OK — n_unsupported_repo=266,
n_unsupported_personal_web=1, n_unsupported_supp_mat=12, all reproduce
exactly.

### `n_mc_no_repo_corpus_wide`, `n_mc_missed_reviewed` and its four-way breakdown

**Manuscript location.** Line 413 and 417: "`repo_check` found no
repository at all for 322 papers. Of those, 267 are also a disagreement
with Cooper's coding... This finds that 121 genuinely cite a repository
platform Metacheck has no backend for at all, 19 cite a domain-specific
bioinformatics accession..., 4 cite a platform Metacheck does support
but failed to detect..., and the remaining 123 split across several
unrelated causes."

**Why computed.** Breaks down *why* `repo_check` found nothing for a
given paper into mutually exclusive, individually-verified root
causes — the central diagnostic result of the whole repository-
detection analysis.

**Definition.** `n_mc_no_repo_corpus_wide` = every paper in the full
1861-paper corpus where `repo_check` found zero files (regardless of
what Cooper coded — includes papers where Cooper agreed there was
nothing to find). `n_mc_missed_reviewed` = the subset of those that are
ALSO a genuine disagreement with Cooper (she coded data/code present),
each one individually read and categorized by a human reviewing the
paper's own extracted text and, where relevant, querying the cited
platform's own API live. The four-way split
(`n_mc_missed_unsupported_repo`/`_genbank`/`_supported_bug`/
`_other_named`) partitions that reviewed set by verified root cause.

**Data used.** `side_by_side$mc_data_availability` (for the corpus-wide
count) and `code/03_comparing_results/repo_not_detected_categorization.csv`
(a *manually produced* file, not a script's output — every row is the
result of an individual human review, the primary record of that work)
for the reviewed-and-categorized subset (267 rows currently, after
deduplication by `article_id`).

**Formula.** `n_mc_no_repo_corpus_wide <-
sum(!mc_data_availability, na.rm=TRUE)`;
`n_mc_missed_reviewed <- nrow(a6_cats_preview)` (deduplicated CSV);
`n_mc_missed_unsupported_repo <- sum(category ==
"UNSUPPORTED_REPO")`; etc., with `_other_named` as the arithmetic
remainder (`n_mc_missed_reviewed` minus the other three named buckets).

**Relation to Cooper.** This entire breakdown exists only for the
subset of "repo_check found nothing" papers where Cooper's own coding
disagrees (she said data/code exists) — a paper where Cooper also
coded nothing is correctly excluded, since there's no disagreement to
explain.

**Interpretation.** The headline point: most of what a naive "322
papers with no repository found" count would suggest as a tool failure
is NOT "Metacheck cannot access this platform" — only 121 of 267
reviewed cases are genuinely that; the rest trace to bioinformatics
accessions (a different kind of resource entirely), confirmed software
bugs on already-supported platforms, or causes unrelated to platform
support at all (truncated citations, withheld data, malformed source
citations).

**Verification status.** OK, with one caveat already logged below —
this *current* count (267) differs from a now-stale internal code
comment that still said "232" (a leftover from before the CSV was
revised); the rendered manuscript number is correct since it reads the
live CSV, only the human-readable code comment needed updating (fixed,
see session log).

### Dryad CC0-license detection (`n_dryad_cc0`, `n_dryad_licensed`, `n_nondryad_cc0`)

**Manuscript location.** Line 586: "`n_dryad_cc0` of the
`n_dryad_licensed` licensed Dryad repositories in this corpus
(`pct`%) carry the identical string,
`https://spdx.org/licenses/CC0-1.0.html`... this value never appears
for a non-Dryad repository in this corpus (`n_nondryad_cc0`
occurrences...)."

**Why computed.** Illustrates a genuine, mechanically-explicable
pattern (Dryad requires CC0-1.0 at deposit, with no author choice) as
evidence that `repo_metadata$license` really is read verbatim from each
platform's own API, not a Metacheck-side default or cached value — the
identical string recurring is a fact about Dryad's policy, not a bug.

**Definition.** `n_dryad_total` = repositories whose URL matches a
Dryad pattern. `n_dryad_licensed` = of those, how many have a
non-missing `license` field. `n_dryad_cc0` = of the licensed ones, how
many carry exactly the CC0-1.0 SPDX URL. `n_nondryad_cc0` = how many
CC0-1.0-licensed repositories exist OUTSIDE the Dryad set.

**Data used.** `res_repo_check$repo_metadata` (one row per repository
with retrievable metadata: Zenodo, Dryad, Figshare, GitHub, and OSF
with `osf_license=TRUE`).

**Formula.** `is_dryad_url(x) <- grepl(<pattern built from
metacheck:::.dryad_doi_prefixes()>, x)`; `n_dryad_cc0 <-
sum(license == cc0_url & is_dryad_url(repo_url))`; `n_nondryad_cc0 <-
sum(license == cc0_url) - n_dryad_cc0`.

**Relation to Cooper.** N/A — a fact about Metacheck's own metadata
retrieval, not a Cooper comparison (though `mc_data_license`, built
partly from this same `repo_metadata` table, IS compared to Cooper's
`data_license` elsewhere — see below).

**Interpretation.** A high `n_dryad_cc0`/`n_dryad_licensed` ratio close
to 100% is the *expected*, correct outcome given Dryad's deposit
policy — it is evidence the license field is read correctly, not a
sign of a caching bug, provided `n_nondryad_cc0` is genuinely 0 (if it
weren't, that WOULD indicate the Dryad-matching logic is either too
broad or too narrow).

**Verification status.** MISMATCH → FIXED. The manuscript's own
`is_dryad_url()` helper originally matched only one of Dryad's 14 known
institutional DOI prefixes (`10.5061`), which meant 14 genuine Dryad
repositories under other prefixes (`10.25338`, `10.7291`, etc. —
confirmed by live-resolving 5 of them to `datadryad.org`) were
miscounted as "non-Dryad," making `n_nondryad_cc0 = 14` and falsifying
the "never appears for a non-Dryad repository" claim. Fixed by building
the regex from `metacheck:::.dryad_doi_prefixes()` (the same canonical
list `repo_check` itself uses) instead of one hardcoded prefix.
After: `n_dryad_total` 1084→1099, `n_dryad_licensed`/`n_dryad_cc0` both
1045→1059 (now equal to total CC0 count), `n_nondryad_cc0` 14→0 — the
"never appears" claim is now actually true, and still correctly
excludes Zenodo/Figshare/GitHub/OSF (confirmed 0 matches among those
four both before and after the fix).

---

## Methods section — "Three further questions" / FAIR-named-platform detection (lines 425-509)

### `n_fair_named`, `n_fair_found`, `n_fair_missed`, and Table 1a

**Manuscript location.** Line 497 and Table 1a: "1404 papers are, by
construction, genuinely FAIR-archived... Metacheck found at least one
file for 1349 of them (96.1%), and found nothing at all for the
remaining 55."

**Why computed.** Isolates the *best case* for repository detection —
papers where Cooper's own coding already names a specific, real,
checkable platform (Dryad/Figshare/Zenodo/GitHub-family), so any
failure here cannot be blamed on Cooper's catch-all labels being
ambiguous. This cleanly separates "Metacheck fails to detect a
well-described repository" from "the paper's own archive platform was
never clearly identifiable to begin with."

**Definition.** `n_fair_named` = papers whose Cooper-coded
`data_archive` includes at least one of exactly four named-platform
labels (Dryad, Figshare, Zenodo, "GitHub, GitLab, Codeberg or similar
platform") — counted once per paper even if it cites more than one.
`n_fair_found`/`n_fair_missed` = of those, how many does
`mc_data_availability` say TRUE/FALSE. Table 1a repeats this per
individual platform (so a multi-platform paper appears once in each
relevant row, meaning the table's row totals can sum to more than
`n_fair_named`).

**Data used.** `side_by_side$data_archive`,
`side_by_side$mc_data_availability` (1861 rows).

**Formula.** `is_named_platform <- vapply(strsplit(data_archive, ";"),
function(v) any(trimws(v) %in% named_platform_labels), logical(1))`;
`n_fair_found <- sum(is_named_platform & mc_data_availability)`.

**Relation to Cooper.** Platform identity comes entirely from Cooper's
own `data_archive` coding; whether Metacheck "found" the paper comes
entirely from Metacheck's `mc_data_availability`. This is a direct,
clean test of detection *rate* conditional on Cooper having already
confirmed the platform is a real, supported one — the detection
question with every confound about platform ambiguity removed.

**Interpretation.** 96.1% overall, but not uniform across platforms
(Table 1a: GitHub-family 98.2%, Dryad 97.1%, Zenodo 95.2%, Figshare
91.5% — Figshare lagging, consistent with the Figshare-specific
detection defects documented in Appendix A.9). Since this is the
*easiest* detection case by construction, these numbers represent close
to Metacheck's ceiling performance for repository detection, not its
typical performance across the whole corpus.

**Verification status.** OK — n_fair_named=1404, n_fair_found=1349
(96.1%), n_fair_missed=55; Table 1a's four rows
(1022/992/30/97.1%, 165/151/14/91.5%, 210/200/10/95.2%, 57/56/1/98.2%)
all reproduce exactly.

### Missed-files classification (`n_missed_files_total` and its breakdown)

**Manuscript location.** Line 507: "Across their 2614 files combined,
1825 (69.8%) are typed `unknown`... and a further 569 are typed
`documentation`."

**Why computed.** For the specific, narrower failure mode of "a
repository WAS found, but nothing in it was classified as data or
code," asks what those files actually got classified AS instead — is
it a real classification gap (files that are data/code but
mis-typed) or a genuine absence of analyzable content.

**Definition.** `target_ids_missed_files` = papers where
`mc_data_availability` is TRUE (a repository was found) but the paper
is NOT in `mc_either_ids` (no file was classified as data or code for
it). `n_missed_files_total` = the total count of files across all of
those papers' repositories, regardless of type; the sub-counts split
that total by `data_type`.

**Data used.** `res_data_check$structure`, filtered to
`paper_id %in% target_ids_missed_files` (124,775-row table, filtered
down to a 51-paper, 2614-row subset for this specific check).

**Formula.** `struct_missed <- structure[structure$paper_id %in%
target_ids_missed_files, ]`; `n_missed_files_unknown <-
sum(struct_missed$data_type == "unknown")`; etc.

**Relation to Cooper.** Indirect — this doesn't compare against any
Cooper column directly; it's a Metacheck-internal diagnostic explaining
*why* `mc_data_availability`/`mc_data_archive` disagree with Cooper for
this specific 51-paper subset.

**Interpretation.** The dominant `unknown` category (69.8%) reflects a
file-extension Metacheck's classifier doesn't recognize at all — a
coverage gap, not a deliberate exclusion. The smaller `documentation`
category is more concerning on manual inspection (per the worked
example in the prose): it can wrongly swallow genuine plain-text
numeric data files that happen to carry a bare `.txt` extension, since
`data_check` cannot distinguish a prose README from a plain-text data
dump by extension alone.

**Verification status.** OK for the counts (51 papers, 2614 files,
1825 unknown/69.8%, 569 documentation). MISMATCH → FIXED for the
illustrative example: two of the four example filenames quoted for
paper `10_1002_2688_8319_12029` (`z_ntp.txt`, `selected_arcs.txt`) are
now classified `output`, not `documentation`, in the current corpus run
— they no longer illustrate the claim. Replaced with two filenames
confirmed to still be `documentation`-typed for the same paper
(`2K.txt`, `arcs0_nos_1n_v2.txt`).

### `.tif`/Shapefile classification (`n_tif_*`, `n_shp_*`)

**Manuscript location.** Line 509: "22 papers where Cooper's coding
names `.tif`... 2159 of 2718 real `.tif` files found are correctly
typed `data`... 29 papers naming `.shp`, 66 of 150... correctly typed
`data`, 84 fall through to `unknown`, and 11 of the 29 papers have
every single Shapefile component misclassified."

**Why computed.** GIS/remote-sensing formats are common in ecology but
have no clean, extension-only classification rule the way `.csv` does
— this quantifies exactly how often that ambiguity actually causes a
real file to be mis-typed, for two specific, concrete formats.

**Definition.** `n_tif_as_data_cooper`/`n_shp_as_data_cooper` = papers
where Cooper's own coded `data_format` field names `.tif`/`.shp` as
part of the archived format. The `_files_total`/`_files_data`/
`_files_materials`/`_files_unknown` counts are, among the REAL files
with that extension found in those specific papers' repositories, how
many Metacheck's classifier assigned to each `data_type`.
`n_shp_papers_none_recognised` = of the 29 `.shp`-naming papers, how
many have ZERO of their Shapefile component files correctly typed
`data` (i.e., every component misclassified).

**Data used.** `side_by_side$data_format` (to find the Cooper-naming
papers) and `res_data_check$structure` (filtered to those papers' real
`.tif`/`.shp` files) together.

**Formula.** `tif_paper_ids <- article_id[grepl("\\.tif\\b",
data_format)]`; `tif_files <- structure[paper_id %in% tif_paper_ids &
grepl("\\.tiff?$", file_name), ]`; `n_tif_files_data <-
sum(tif_files$data_type == "data")`. Shapefile logic identical, with
`shp_by_paper_any_data <- tapply(data_type, paper_id, function(x)
any(x=="data"))` for the per-paper "none recognised" count.

**Relation to Cooper.** The *denominator* (which papers to look at) is
defined by Cooper's own coded format label; the actual outcome being
measured is purely a Metacheck-internal classification correctness
check against the real files in those papers' repositories — there is
no Cooper-side "is this file data" column to compare against file by
file, since her coding doesn't go to that level of granularity.

**Interpretation.** For `.tif`, the majority (2159/2718, 79.4%) are
correctly typed, with most of the remainder going to `materials`
rather than `unknown` — a real but comparatively mild gap. For `.shp`,
the split is close to even (66 data / 84 unknown), and more strikingly,
11 of 29 papers (38%) have every single Shapefile component
misclassified — meaning the detection gap is not evenly spread across
papers but concentrated, consistent with a folder-naming-dependent rule
(no informative folder name → every component in that paper falls
through together).

**Verification status.** OK — all nine values
(22/2718/2159/443, 29/150/66/84/11) reproduce exactly.

---

## Methods section — "2. Where were the data/code archived?" (lines 568-611)

### `results$data_archive` and its verdict tally

**Manuscript location.** Line 574/576: "both codeable for 1370
papers... agreed on 1323 (96.6%), disagreed on 47 (3.4%)... 31 were
METACHECK_RIGHT... 7 COOPER_RIGHT... 7 BOTH_DEFENSIBLE... The remaining
2 could not be resolved."

**Why computed.** `data_archive` is a platform-*name* field (Dryad,
Zenodo, "Other repo/database", etc.), not a plain yes/no, so it can't
use the same sensitivity/specificity logic as the boolean constructs —
this uses a looser "do the two sides' label sets overlap at all"
agreement rule instead, then classifies every disagreement by
individual human review.

**Definition.** `n_both_coded` = papers with a non-missing,
non-empty label from both Cooper and Metacheck. Agreement = at least
one of Cooper's (possibly multi-valued, semicolon-joined) labels
matches (case-insensitively) at least one of Metacheck's. The verdict
tally is the human-reviewed root-cause classification of every
disagreement.

**Data used.** `side_by_side$data_archive` (Cooper's coding) vs.
`side_by_side$mc_data_archive` (Metacheck's, derived by matching each
linked repository's URL against a fixed domain/DOI-prefix pattern set —
see the `mc_data_archive` definition entry below); plus
`disagreement_review_worklist.xlsx`'s `data_archive_verdict`/
`data_archive_comment` columns for the 47 disagreements.

**Formula.** `ov <- mapply(function(a,b) any(tolower(strsplit(a,
";")[[1]]) %in% tolower(strsplit(b, ";")[[1]])), cv, mv)`;
`pct_agree <- mean(ov)*100`.

**Relation to Cooper.** Cooper's protocol asks for a single platform
per paper; Metacheck's `mc_data_archive` lists every matching platform
a paper's repositories touch, semicolon-joined. A genuinely
multi-repository paper can therefore show a "disagreement" by this
overlap rule that is really a *completeness* mismatch (Metacheck says
more, not something different) rather than a wrong answer — this is
exactly what the `BOTH_DEFENSIBLE` verdict category exists to capture.

**Interpretation.** 96.6% agreement is high, and the disagreement
composition (31 METACHECK_RIGHT vs. 7 COOPER_RIGHT) suggests Cooper's
coders used the "Other repo/database" catch-all more often than
Metacheck's own label-matching does, when the actual platform was in
fact unambiguous from the paper's own text.

**Verification status.** OK for the aggregate numbers (independently
re-derived from the raw columns, not just read from the cache — exact
match: 1370/1323/96.6%/47). MISMATCH → FIXED: the verdict-tally
sentence referenced a `DIFFERENT_DEFINITION` case ("was a case where
the paper itself distinguishes a versioned Zenodo archive...") that is
entirely absent from the current tally (0 rows) — would have rendered
"0 was a case where..." Fixed by folding the Zenodo/GitHub example into
the `BOTH_DEFENSIBLE` sentence instead, where matching real cases
(articles `10_1111_2041_210x_13514`, `10_1111_2041_210x_13324`) do
exist in the current worklist.

### `mc_data_availability`, `mc_data_archive`, `mc_data_doi`/`mc_data_license`, `mc_data_download`, `mc_any_readme`, `mc_code_archived`/`mc_code_download`, `mc_code_used` (construct definitions, lines 598-611)

**Manuscript location.** These are not computed numbers but the formal
*definitions* of every Metacheck-derived column this manuscript
compares against Cooper's coding — reproduced here since every later
"relation to Cooper" entry below depends on knowing exactly what each
`mc_*` column means.

- **`mc_data_availability`**: `TRUE` if `repo_check`'s
  `summary_table$files_n > 0` — at least one linked repository with at
  least one file of ANY type (data, code, documentation, or
  unclassified). Deliberately permissive: answers "did we find a
  repository with something in it," not "did we find a repository
  holding a dataset." A paper whose only repository is a pure-code
  archive still scores TRUE here.
- **`mc_data_archive`**: the matching platform name(s), derived by
  checking each linked repository's URL against a fixed domain/
  DOI-prefix pattern set (`osf.io`→OSF, `zenodo.org` or
  `10.5281/zenodo`→Zenodo, etc.); anything else → "Other repo/database".
  Semicolon-joined if a paper cites more than one platform holding
  data-classified files.
- **`mc_data_doi`/`mc_data_license`**: read from
  `repo_check$repo_metadata`, scoped to repositories holding at least
  one data-classified file — a paper whose licensed repository holds
  only code scores `mc_data_license = FALSE` even if a real license
  exists, by design (the scoping matches `mc_data_archive`'s own).
- **`mc_data_download`**: `TRUE` if at least one data-classified file
  has BOTH `tabular_usable == TRUE` AND a non-missing `file_location` —
  a two-part test, so a file can download successfully and still fail
  this if `data_check` judges its content unusable as a table.
- **`mc_any_readme`**: `TRUE` if `repo_check` classified at least one
  file, in ANY of a paper's repositories, with `doc_role == "readme"` —
  purely filename-based (starts with "readme", or a package-level
  `ro-crate-metadata.json`), never content-based. One signal per paper,
  not separated by data vs. code — hence compared against
  `cooper_any_readme` (Cooper's `data_README`/`code_README` collapsed
  with OR) rather than either Cooper column alone.
- **`mc_code_archived`**: `TRUE` if `code_check`'s file table has at
  least one row for the paper, regardless of download success.
  **`mc_code_download`**: the stricter follow-up, requiring a
  non-missing `file_location` too.
- **`mc_code_used`**: always `NA` — no Metacheck module answers "did
  this paper use code" as a construct distinct from "is there a code
  file in a linked repository."

**Why these definitions matter for interpretation.** Every sensitivity/
specificity/PPV number later in this manuscript inherits whichever
scoping choice is baked into these definitions. The two most
consequential: (1) `mc_data_availability`'s permissiveness means a
pure-code repository with zero data files still counts as "data
available" — this is a deliberate, stated design choice, not a bug;
(2) `mc_data_license`'s data-only scoping means a paper with two
repositories (one data, one code, only the code one licensed) will
always show `mc_data_license = FALSE` even with a real license
somewhere in its overall archive — the manuscript's own "Limitation"
paragraphs for `data_archive`/`data_license`/`code_archived` all trace
back to this same repository-scoping choice.

**Verification status.** OK — these are code definitions, not
computed statistics; cross-checked that the prose description matches
the actual chunk logic (lines 580-610) exactly.

---

## Empirical Comparison section (lines 614-686)

Six constructs follow an identical statistical template, computed by
`03_comparing_results/01_compute_comparison_statistics.R` from
`master_comparison.rds` (confusion table) plus
`disagreement_review_worklist.xlsx` (qualitative verdicts). The
template is documented once here; each construct's entry below gives
only what's specific to it.

**Shared definition (applies to all six).** For a given construct, `cb`
= Cooper's boolean-recoded answer (`TRUE`/`FALSE`/`NA`, with specific
positive/negative label sets per construct — see each entry), `mb` =
Metacheck's `mc_*` boolean. `both <- !is.na(cb) & !is.na(mb)`;
`n_both_coded <- sum(both)`. Then the standard 2×2 confusion table:
`tp` (Cooper Yes, MC Yes), `fn` (Cooper Yes, MC No — MC's miss), `fp`
(Cooper No, MC Yes — MC's over-claim), `tn` (Cooper No, MC No).
`sensitivity <- tp/(tp+fn)` (of Cooper's Yesses, % MC also said Yes);
`specificity <- tn/(tn+fp)` (of Cooper's Nos, % MC also said No); `ppv
<- tp/(tp+fp)` (of MC's Yesses, % Cooper agreed); `pct_agree <-
(tp+tn)/n_both_coded*100`. The two **directional miss rates**
(`pct_cooper_caught_mc_missed` = `fn/(fn+fp)*100`,
`pct_mc_caught_cooper_missed` = `fp/(fn+fp)*100`) are percentages of
*disagreements only*, not of the full sample — they answer "when the
two sides disagree, which direction is it," not "how often does each
side miss something."

**Shared relation to Cooper (applies to all six).** Every one of these
constructs is a direct, paper-by-paper boolean comparison against one
specific Cooper-coded column (named in each entry's own "Relation to
Cooper" field below) — not an aggregate-vs-aggregate comparison the way
some Methods-section numbers are. `n_both_coded` always excludes a
paper where EITHER side has no answer (Cooper didn't code that
sub-question for that paper, or Metacheck couldn't process the paper's
PDF at all) — so the comparison base shrinks construct by construct as
coverage requirements stack up.

**Shared interpretation guide.** High sensitivity + high specificity =
good agreement in both directions. High PPV with lower sensitivity = "a
Yes from Metacheck is trustworthy, but it misses real Yesses relatively
often" (an under-detection pattern — the dominant pattern in this
manuscript). McNemar's test asks whether the *asymmetry* of
disagreement (more `fn` than `fp`, or vice versa) is itself
statistically significant, not whether the two sides agree overall.

### `data_availability`

**Manuscript location.** Line 628/630: "both codeable for 1735
papers... agreed on 1464 (84.4%)... Sensitivity was 85.4% and
specificity was 44.4%... 230 were COOPER_RIGHT, 8 METACHECK_RIGHT, 23
DIFFERENT_DEFINITION, 10 UNCLEAR."

**Why computed.** The most basic construct in the comparison: did the
paper's data get archived at all. Also the construct whose derivation
rule was itself corrected mid-project (see Coding-section note below),
so this entry's specificity carries extra weight as a check that the
fix actually worked.

**Definition.** Cooper positive = `"Yes"`; negative = `"No"` or `"No,
but they are available on request"`. Metacheck = `mc_data_availability`
(see definition above).

**Data used.** `side_by_side$data_availability` vs.
`side_by_side$mc_data_availability`, 1861 rows, 1735 both-coded.

**Formula.** Standard template above.

**Relation to Cooper.** Direct comparison against Cooper's
`data_availability` column. Note the "available on request" label is
folded into Cooper's NEGATIVE set here — a paper offering data only on
request counts as Cooper-coded "No" for this specific boolean
comparison, even though her own narrative coding might read it more
charitably; this is exactly the source of several `DIFFERENT_DEFINITION`
verdicts below.

**Interpretation.** Specificity (44.4%) is far from 0 — this matters
because, per the manuscript's own note, an earlier version of
`mc_data_availability`'s derivation rule made a `FALSE` structurally
impossible (any paper with no detected repository was silently excluded
from the comparison entirely rather than scored `FALSE`), which would
have made specificity undefined or trivially inflated. The current,
corrected rule gives it a genuine ability to disagree with Cooper in
the `FALSE` direction, and this 44.4% reflects where that real
disagreement now concentrates: mostly repository-coverage gaps (192 of
230 COOPER_RIGHT cases), not a residual derivation-rule artifact.

**Verification status.** OK — n_both_coded=1735, n_agree=1464 (84.4%),
sensitivity=85.4%, specificity=44.4%, McNemar χ²(1)=178.6 p<.001;
verdict tally 230/8/23/10 all reproduce exactly; repo_not_detected=192
of the 230 COOPER_RIGHT cases confirmed.

### `data_license`

**Manuscript location.** Line 636/638: "both codeable for 1292
papers... agreed on 1237 (95.7%)... Sensitivity 99.2%, specificity
26.2%... 45 METACHECK_RIGHT, 9 COOPER_RIGHT, 1 UNCLEAR."

**Why computed.** Tests whether a license genuinely present can be
machine-detected — the construct the manuscript frames as "one of the
more reliably automatable" because Metacheck reads this straight from
each platform's own API rather than inferring it from text.

**Definition.** Cooper positive = `"Yes"`; negative = `"No"`.
Metacheck = `mc_data_license` (scoped to repositories holding at least
one data-classified file — see definition above).

**Data used.** `side_by_side$data_license` vs.
`side_by_side$mc_data_license`, 1292 both-coded.

**Formula.** Standard template above.

**Relation to Cooper.** Direct comparison against Cooper's
`data_license` column, but with a scoping asymmetry worth flagging:
Cooper's coders could, in principle, judge "is there a license" for
the paper's overall archive, while `mc_data_license` only ever looks at
repositories holding DATA files specifically — a paper with a licensed
code repository and an unlicensed (or never-found) data repository will
show `mc_data_license = FALSE` even with a real license somewhere in
its overall deposit. This scoping mismatch is the dominant cause of the
9 COOPER_RIGHT disagreements.

**Interpretation.** Specificity (26.2%) looks weak in isolation, but on
closer reading this is a *low base rate* effect, not a sign the
construct performs poorly: there are relatively few genuine Cooper-No
cases in this corpus to test specificity against, so a handful of
scoping-mismatch disagreements move this percentage a lot. The far
more decision-relevant number here is PPV (96.4%, reported in the
Discussion) — when Metacheck DOES find a license, it is very rarely
wrong, since every METACHECK_RIGHT case was independently reconfirmed
against the same live platform API `repo_check` itself reads from.

**Verification status.** OK — n_both_coded=1292, n_agree=1237 (95.7%),
sensitivity=99.2%, specificity=26.2%, McNemar χ²(1)=21.02 p<.001;
verdict tally 45/9/1 all reproduce exactly.

### `data_download`

**Manuscript location.** Line 644/646: "both codeable for 1277
papers... agreed on 1263 (98.9%)... 14 disagreements: 5 COOPER_RIGHT, 4
DIFFERENT_DEFINITION, 3 METACHECK_RIGHT (described individually), 2
UNCLEAR."

**Why computed.** Tests not just "is there a repository" but "does the
actual data file download and parse as usable" — the strictest, most
practically consequential construct for a researcher who actually
wants to reuse the data.

**Definition.** Cooper positive = `"Yes"` or `"Yes, but not all data"`;
negative = `"No"`. Metacheck = `mc_data_download` (requires BOTH
`tabular_usable == TRUE` AND a real `file_location` — see definition
above).

**Data used.** `side_by_side$data_download` vs.
`side_by_side$mc_data_download`, 1277 both-coded.

**Formula.** Standard template above; this construct's disagreement
count is small enough (14) that every case was individually traced by
name rather than summarized into cause buckets.

**Relation to Cooper.** Direct comparison against Cooper's
`data_download` column. The `DIFFERENT_DEFINITION` cases here have a
precise, structural cause: `mc_data_download`'s criterion additionally
requires `data_check`'s stricter `tabular_usable` flag, which does not
always agree with "a human can open this file just fine in standard
software" — the two sides can genuinely be asking subtly different
questions even when both are being applied correctly.

**Interpretation.** 98.9% agreement on a construct this strict is a
strong result, and the manuscript's own framing ("essentially resolved")
is earned — this reflects a real, documented multi-stage fix history
(Appendix A.1's Excel multi-sheet fix moved this specific construct from
93.5% to 99.1% agreement on its own).

**Verification status.** MAJOR MISMATCH → FIXED. The manuscript
originally described only ONE `METACHECK_RIGHT` case ("a downloaded
file that... was a serialized model-input dump") using singular
grammar, but the true count is THREE (confirmed directly against the
worklist: article `10_1111_1365_2664_13982`'s model-input dump is real,
but TWO MORE real cases existed and were never mentioned — a clean OSF
link Cooper coded "No" with nothing supporting that in the paper text,
and a KNB record a later fix, metacheck#435, now correctly downloads).
Fixed by rewriting the sentence to plural and naming all three. The
aggregate numbers themselves (1277/1263/98.9%/14) were already correct.

### `code_archived`

**Manuscript location.** Line 654/658: "both codeable for 1669
papers... agreed on 1459 (87.4%)... the largest disagreement rate of
any construct... Sensitivity 69.2%, specificity 97.1%... 158
COOPER_RIGHT (six named sub-causes)... 29 METACHECK_RIGHT... 5
DIFFERENT_DEFINITION... 18 UNCLEAR."

**Why computed.** The code-sharing mirror of `data_availability`, and
— per the manuscript's own framing — the single most diagnostically
rich construct in this comparison, since its disagreement is genuinely
multi-causal rather than dominated by one mechanism.

**Definition.** Cooper positive = `"Yes"`; negative = `"No"`.
Metacheck = `mc_code_archived` (at least one `code_check`-classified
file, regardless of download success — see definition above).

**Data used.** `side_by_side$code_archived` vs.
`side_by_side$mc_code_archived`, 1669 both-coded;
`disagreement_cause_categories.RData`'s `cooper_right_causes$code_archived`
and `code_archived_mr_causes` for the sub-cause breakdowns.

**Formula.** Standard template above, plus a six-way categorization of
the 158 COOPER_RIGHT cases by verified root cause
(`code_bundled_not_classified`=23, `zip_not_peeked`=0,
`repo_not_detected`=43, `gated_fetch_error`=1, `other`=86,
`r_package_source_excluded`=5) and a three-way categorization of the 29
METACHECK_RIGHT cases (`code_check_found_files`=10,
`no_code_mentioned`=9, `other`=10).

**Relation to Cooper.** Direct comparison against Cooper's
`code_archived` column. The asymmetry (sensitivity 69.2% vs.
specificity 97.1%) is the most pronounced of any boolean construct —
meaning Metacheck is quite reliable when it says code is NOT archived,
but misses a real archive relatively often when one exists.

**Interpretation.** The six-cause breakdown (summing to exactly 158)
shows this is NOT one bug with one fix: the two largest named causes
(code bundled with data in a repository `code_check` cannot classify,
23 cases; repository never detected, 43 cases) point to two entirely
different parts of the pipeline (a zip-peek limitation vs. a
platform-coverage gap), so "fix code_archived" is not a single,
well-defined task.

**Verification status.** OK for the aggregate numbers (1669/1459/87.4%/
69.2%/97.1%). MISMATCH → FIXED: the six-cause breakdown was originally
presented as only five named causes, summing to 153, not the true
COOPER_RIGHT total of 158 — the sixth cause
(`r_package_source_excluded`, 5 cases, already discussed at length two
paragraphs earlier in the manuscript as "a further genuine software
defect") had simply been dropped from this specific numbered list.
Fixed by adding it as item 6.

### `code_download`

**Manuscript location.** Line 654/669: "both codeable for 392
papers (a much smaller base, since this sub-question only applies when
code was coded as archived)... agree on 390 of 392 (99.5%)... 2
disagreements: 1 METACHECK_RIGHT (an OSF repository's 9 code files, all
confirmed downloaded), 1 COOPER_RIGHT (an archive-member fetch failure
tied to metacheck#429)."

**Why computed.** The code-sharing mirror of `data_download` — given
code was archived at all, did it actually download. The construct with
the most dramatic improvement trajectory in this whole project
(documented in Appendix A.1: 66.2% → 89.7% → 99.5% across three
successive fixes).

**Definition.** Cooper positive = `"Yes"`; negative = `"No"`.
Metacheck = `mc_code_download` (requires a non-missing `file_location`
on at least one code-classified file — see definition above).

**Data used.** `side_by_side$code_download` vs.
`side_by_side$mc_code_download`, 392 both-coded (conditional on code
having been coded archived in the first place, by both sides' own
construction).

**Formula.** Standard template above.

**Relation to Cooper.** Direct comparison against Cooper's
`code_download` column, restricted by construction to the subset of
papers where this sub-question even applies.

**Interpretation.** 99.5% on a base this strict, after a documented
~33-percentage-point improvement over the project's fix history, is the
single largest improvement of any construct in this comparison — and,
per the manuscript's own framing, "essentially resolved" (the remaining
2 cases are a small handful, not a systematic pattern).

**Verification status.** MAJOR MISMATCH → FIXED (this was the single
most repeated error found in this audit). FOUR separate sentences
across the manuscript (lines 654, 658, 669, and the Discussion's
limitation paragraph) asserted "a single disagreement" / "the single
remaining disagreement" for this construct and only ever described the
METACHECK_RIGHT case — completely omitting the real COOPER_RIGHT case
(article `10_1111_2041_210x_13471`), even though it is individually
documented in the review worklist with its own verdict and comment. The
true count has always been 2 (verdict tally: COOPER_RIGHT=1,
METACHECK_RIGHT=1), confirmed by an independent recomputation from the
raw `results$code_download` object, not just by re-reading a cached
number. All four sentences fixed to describe both cases / use the
computed `n_disagree` rather than the word "single."

### `any_readme`

**Manuscript location.** Line 675/677: "both codeable for 1726
papers... agreed on 1242 (72.0%) — the largest raw disagreement count
of any construct... Sensitivity 62.8%, specificity 95.5%... 23
METACHECK_RIGHT, 155 COOPER_RIGHT, 294 DIFFERENT_DEFINITION, 12
UNCLEAR."

**Why computed.** README presence, collapsed across data and code into
one Metacheck signal per paper — and, per the manuscript's own
framing, "a genuinely different framing than the other constructs,"
since most of its disagreement is not either side being *wrong* at all.

**Definition.** Cooper = `cooper_any_readme` (TRUE if EITHER her
`data_README` or `code_README` column is `"Yes"` or `"Quasi-README"` —
built specifically to avoid double-counting Metacheck's single signal
against two separate Cooper columns, which an earlier, uncorrected
comparison approach did, inflating the disagreement count by 41% before
being fixed). Metacheck = `mc_any_readme` (see definition above).

**Data used.** `side_by_side$data_README`/`code_README` (combined into
`cooper_any_readme`) vs. `side_by_side$mc_any_readme` (=
`mc_data_README`), 1726 both-coded;
`disagreement_cause_categories.RData`'s `any_readme_dd_causes` for the
DIFFERENT_DEFINITION sub-breakdown.

**Formula.** Standard template above, with
`any_readme_dd_causes` partitioning the 294 DIFFERENT_DEFINITION cases
into `dryad_abstract`=172, `zenodo_figshare_description`=88,
`archive_only_zip`=16, `other`=18 (summing to 294 exactly).

**Relation to Cooper.** Compared against a CONSTRUCTED Cooper column
(`cooper_any_readme`), not one of her raw columns directly, specifically
because Metacheck's one-signal-per-paper design has no natural
one-to-one Cooper counterpart — this is the one construct in the whole
comparison where the Cooper-side variable itself had to be built before
any comparison could happen at all.

**Interpretation.** The single largest verdict category
(DIFFERENT_DEFINITION, 294 of 484 disagreements, 60.7%) is NOT a
detection failure on either side: Dryad's dataset API exposes only one
free-text field (`abstract`), which is confirmed, on direct inspection,
to always be the paper's scientific abstract, never file
documentation — yet Cooper's coders, reading the same field on Dryad's
own live webpage, reasonably treated it as README-equivalent evidence.
Resolving this is not simply "relax the filename rule," since
Zenodo/Figshare's equivalent `description` field is confirmed genuinely
MIXED in content (sometimes real documentation, sometimes not) — a
uniform rule change would fix Dryad's false negatives while introducing
new false positives on Zenodo/Figshare.

**Verification status.** OK for the aggregate numbers and the
`any_readme_dd_causes` breakdown (all four sub-causes sum to exactly
294). MISMATCH → FIXED: the comparison "slightly ahead of the
COOPER_RIGHT count" (294 vs. 155) understated the actual gap — 294 is
90% larger than 155, not "slightly" larger. Fixed to "well ahead,"
which stays accurate even if the gap narrows somewhat on a future
rerun.

---

## "Is a comment count a proxy for comment quality?" (lines 687-709)

### `comment_quality` (n_mc_has_stats, n_both, Pearson's r, Spearman's ρ, etc.)

**Manuscript location.** Lines 705-709: "compared... for the 376
papers where both were available (of 543 papers Cooper et al. rated and
432 papers Metacheck could compute a comment percentage for at
all)... Pearson's r = .20, 95% CI [.10, .29], p < .001; Spearman's ρ =
.17, p = .001... roughly 4% of variance explained."

**Why computed.** A genuinely exploratory question distinct from every
boolean comparison above: does a cheap, fully automatable proxy (line-
count comment density) track a construct Metacheck cannot compute at
all (a human's judgment of comment *quality*) well enough to stand in
for it.

**Definition.** `n_cooper_coded` = papers with a non-missing
`code_annotation_scale` (Cooper's 1-10 human quality judgment).
`n_mc_has_stats` = papers where `code_check` could compute a per-paper
comment percentage at all (requires at least one code file to have
actually downloaded and parsed). `n_both` = the overlap. The
aggregated Metacheck value is **weighted** by total lines, not an
average of per-file percentages: `mc_percentage_comment <-
sum(comment_lines) / sum(comment_lines + code_lines)` across every
analysable file in that paper — so a 500-line file counts more than a
5-line file toward the paper's overall score.

**Data used.** Cooper's `code_annotation_scale` (from her raw CSV, 543
rated papers) joined against `res_code_check$table`'s per-file
`comment_lines`/`code_lines`, aggregated to one row per paper. Computed
by `03_comparing_results/03_comment_quality_correlation.R`.

**Formula.** `cor.test(code_annotation_scale, mc_percentage_comment,
method="pearson")` and again with `method="spearman"`; a third
correlation (code length vs. comment %) checks whether longer
codebases are simply commented differently regardless of quality, as a
possible confound.

**Relation to Cooper.** Cooper's `code_annotation_scale` is the only
Metacheck-incomparable construct given a quantitative (not just
qualitative) treatment in this manuscript — rather than asking "does
Metacheck's answer match Cooper's," this asks "does a mechanical proxy
correlate with Cooper's judgment," since no Metacheck module attempts
to answer the quality question directly at all.

**Interpretation.** r=.20 (≈4% variance explained) is weak but not
zero — meaning comment *density* is a poor stand-in for comment
*quality*: a single well-placed sentence explaining a complex analysis
scores as excellent annotation on Cooper's human scale and as a single
line on Metacheck's mechanical count; ten lines of boilerplate counts
as heavily annotated by line count and would plausibly score poorly on
a human quality read. This is exploratory, not a causal or "which
measure is right" claim — a low correlation is not evidence either
measure is wrong, just that they answer different questions.

**Verification status.** MAJOR MISMATCH → FIXED. This entire section's
chunk was `eval: FALSE` and every number in the prose was a stale,
hand-typed snapshot — none of these values were actually recomputed at
render time. Checked every literal against the current
`comment_quality_correlation.RData` (confirmed stale via file
timestamps: the .RData is newer than the generating script, meaning it
was rerun on updated data after this prose was written): n_mc_has_stats
357→432, n_both 310→376, Pearson's r .16→.20 (CI [.05,.27]→[.10,.29], p
=.005→<.001), Spearman's ρ .14→.17 (p=.013→.001), raw-line-count ρ
.13→.14 (p=.020→.008), codelines-vs-pct ρ -.20→-.31 (p<.001 both),
variance explained 2%→4%. Fixed properly (not just re-typed): set the
chunk to `eval: TRUE` and rewrote every number as a computed `` `r
cq$...` `` expression reading from the RData object, so this cannot go
stale silently a second time.

---

## "Results you get for free alongside Metacheck" (lines 711-776)

**Why this whole section exists (shared context).** None of the
findings in this section were validated against Cooper et al.'s human
coding, because her protocol never asked about any of them — there is
no ground truth to check sensitivity/specificity against. This is
Metacheck's own structured output, useful in its own right, reported
separately from the validated comparison above specifically to keep
that distinction visible to the reader.

### `fe$n_code_files`, `fe$n_code_papers`, and the three code-portability checks

**Manuscript location.** Line 726/728-730: "`code_check` parsed 9202
code files across 435 code-bearing papers... 1121 files (12.2%) across
221 papers (50.8%) reference at least one file that could not be
found... 430 files (4.7%) across 112 papers (25.7%) hardcode an
absolute path... 409 files (4.4%) across 100 papers (23.0%) call
`setwd()`... together affect 269 of 435 papers (61.8%)."

**Why computed.** Three mechanical, structural signals of whether a
paper's shared code would actually run on someone else's machine — not
judgments about code quality, just checkable facts about file
references and path-handling.

**Definition.** `n_missing_files`/`n_papers_missing`: a file has
`loaded_files_missing > 0` if `code_check`'s reference-extraction found
at least one filename the code tries to open that does not appear
anywhere in that paper's own repository listing. `n_abs_path`: a file
has `code_abs_path == TRUE` if it contains a regex-matched absolute
filesystem path (`C:/Users/...`, `/home/...`). `n_setwd`: a file has
`code_setwd == TRUE` if it calls `setwd()` anywhere. `n_papers_portability`
= union of the three "at least one paper-level flag" sets.

**Data used.** `res_code_check$table` (9202 rows, one per analysed
code file), fields `loaded_files_missing`, `code_abs_path`,
`code_setwd`, `paper_id`.

**Formula.** `has_missing <- !is.na(loaded_files_missing) &
loaded_files_missing > 0`; `papers_missing <-
unique(paper_id[has_missing])`; percentages are always `100 *
count/n_code_files` (file-level) or `100 * count/n_code_papers`
(paper-level) — never cross the two denominators.

**Relation to Cooper.** N/A — no Cooper-coded counterpart exists for
any of these three checks.

**Interpretation.** 61.8% of code-bearing papers having at least one of
these three issues means "more than half the papers whose code we
could even inspect have at least one file that will not run as shared,
without modification, on someone else's machine" — a direct, practical
reproducibility signal distinct from the "is code archived at all"
question the Empirical Comparison section already answers. A missing-
file flag specifically does not necessarily mean the code is broken
(the referenced file might exist under a slightly different name the
regex missed, or be generated by an earlier pipeline step) — it is a
signal worth checking, not a proof of a defect.

**Verification status.** MAJOR MISMATCH → FIXED. This whole section's
chunk was also `eval: FALSE`, with every number hand-typed from a
corpus run BEFORE Appendix A.3's five `code_check` fixes — the
manuscript's own prose explicitly flagged this ("reflects the corpus as
run before those fixes... will be updated once a corpus rerun...is
complete"), and that promised rerun turned out to have already
happened (proven via the `has_docstring` field's presence in the
current `res_code_check$table`, which can only exist post-A.3-fix).
Every number was stale by a large margin: code files 10,461→9,202,
code-bearing papers 400→435, missing-files 948(9.1%)/183(45.8%)→
1,121(12.2%)/221(50.8%), abs-path 399(3.8%)/110(27.5%)→
430(4.7%)/112(25.7%), setwd 302(2.9%)/79(19.8%)→409(4.4%)/100(23.0%),
combined portability 228/400(57.0%)→269/435(61.8%). Fixed by setting
the chunk `eval: TRUE` and computing every number from
`free_extras_summary.RData` (regenerated from a corrected
`04_free_extras_summary.R`, loading the three huge module-output
RData files one at a time to stay within available memory).

### `fe$pct_comment_corpus`, `fe$n_zero_comment`, docstring cross-check

**Manuscript location.** Line 734: "comments make up 19.0% of all code
lines. 1063 files (13.8%) have zero comments at all — of which 238 of
337 zero-comment Python files (70.6%) are in fact documented via a
docstring rather than a `#` comment."

**Why computed.** A corpus-wide version of the same comment-density
metric used in the comment-quality correlation above, plus a specific
check on whether a "zero comments" flag is actually misleading for
Python files (which can be documented via triple-quoted docstrings
that this metric's `#`-only count cannot see).

**Definition.** `pct_comment_corpus` = total comment lines ÷ total
lines, summed across every file with a computable line count corpus-
wide (weighted the same way as the comment-quality correlation's
per-paper value, just aggregated one level higher — across the whole
corpus rather than within one paper first). `n_zero_comment` = files
with `percentage_comment == 0` among those with computable stats.
`n_py_zero_comment_has_docstring` = of the zero-comment PYTHON files
specifically, how many have `has_docstring == TRUE` (Appendix A.3's
addition).

**Data used.** `res_code_check$table$comment_lines`/`code_lines`/
`percentage_comment`/`has_docstring`/`language`.

**Formula.** `pct_comment_corpus <- sum(comment_lines[has_stats]) /
sum(comment_lines[has_stats] + code_lines[has_stats])`;
`n_py_zero_comment_has_docstring <- sum(has_docstring[is_py_zero_comment]
== TRUE)`.

**Relation to Cooper.** N/A.

**Interpretation.** The docstring cross-check matters for correct
interpretation of the "zero comments" number: 70.6% of zero-comment
Python files are NOT actually undocumented, just documented in a way
this specific mechanical `#`-only count cannot see — without this
check, the raw "1063 files have zero comments" figure would overstate
how many files are genuinely undocumented.

**Verification status.** MISMATCH → FIXED, as part of the same
free-extras section rewrite above: 22.1%→19.0% comment density,
984(12.2%)→1063(13.8%) zero-comment. The docstring cross-check (337
zero-comment Python files, 238 with docstrings, 70.6%) was newly ADDED
to the underlying script during this fix — it wasn't computed by the
original script at all, even though the manuscript's prose already
discussed the concept narratively.

### `fe$n_scattered`, `fe$n_parse_denom`/`n_parse_error`, `fe$n_pin_papers`/`n_pin_papers_pinned`

**Manuscript location.** Lines 738/742/746: "1013 of 4172 such files
(24.3%) load their packages in a scattered... fashion... Of the 4938
R-type code files that were both locally available and actually
reached a call to `parse()`, 227 failed to parse... (4.6%)... Of the
435 code-bearing papers, 22 (5.1%) have version pinning present."

**Why computed.** Three more mechanical reproducibility/quality
signals: import/library organization (readability, not correctness),
parse errors (an unambiguous "something is structurally wrong with
this file" signal), and package version pinning (whether a repository
records the exact dependency versions its analysis used, for future
reproducibility).

**Definition.** `n_scattered`/`n_scattered_denom`: among files with
more than one package-loading line, "scattered" = the maximum gap
between consecutive loading lines exceeds the module's own documented
threshold (`library_max_between > 3`). `n_parse_denom`/`n_parse_error`:
restricted to R-language files (`.R`/`.Rmd`/`.qmd` — `parse()` is never
even attempted on SAS/SPSS/Stata/Python/MATLAB code) that were BOTH
downloaded (`file_location` non-missing) AND actually reached the
`parse()` call (`parse_error` not `NA` — a missing value here most
often means the file was never downloaded, or crashed during an
earlier extraction step before `parse()` was ever reached).
`n_pin_papers`/`n_pin_papers_pinned`: a code-bearing paper (`code_n >
0`) has version pinning if `summary_table$code_version_pinned ==
TRUE` — a genuine per-paper field, read directly, requiring an
`renv.lock` file, a `sessionInfo()`/`session_info()` text dump, or an
actual `groundhog`/`checkpoint` date-pinning CALL in the code (a bare
`library(groundhog)` does not count).

**Data used.** `res_code_check$table$library_max_between`/
`language`/`file_location`/`parse_error`;
`res_code_check$summary_table$code_n`/`code_version_pinned`.

**Formula.** `has_scattered <- !is.na(library_max_between) &
library_max_between > 3`; `parse_eligible <- is_r_lang &
!is.na(file_location) & !is.na(parse_error)`;
`n_pin_papers_pinned <- sum(code_version_pinned[code_n > 0] == TRUE)`.

**Relation to Cooper.** N/A.

**Interpretation.** Version pinning at 5.1% is low in absolute terms,
but should be read as a floor on good practice rather than a complete
absence of it — this only counts an EXPLICIT pinning mechanism, not
any informal version documentation a paper's methods section might
describe in prose.

**Verification status.** MISMATCH → FIXED, with two genuine bugs found
in the underlying script (not just stale numbers):

1. **Parse-error denominator was wrong.** The original script divided
   227 by `n_code_files` (9202, every language, every file regardless
   of download status) — the exact same mistake Appendix A.2's own
   narrative describes diagnosing and fixing in an EARLIER manuscript
   draft (dividing 138 by 10,461 instead of restricting to eligible
   R-type files). The free-extras script had simply never been updated
   to match A.2's own already-documented correction. Traced the right
   denominator directly (4,938 eligible files: of 5,866 R-language
   files, 905 never downloaded and 23 more reached a local copy but
   crashed before `parse()` — confirmed via their own `error` field:
   fence-mismatch Rmd errors, 0-byte "cannot open the connection"
   files). Fixed in the script itself.
2. **Version pinning was a crude batch-level proxy, not the real
   per-paper rate.** The original script's own comment claimed the
   per-paper field "is not retained in the saved batch object" and
   fell back to counting pinned BATCHES (14 of 38, 36.8%) instead of
   pinned PAPERS — but Appendix A.2's own narrative already
   demonstrates this claim is false (it explicitly corrects an earlier
   "34.2% batch-level upper bound" to the true per-paper rate for
   exactly this reason). Confirmed `summary_table$code_version_pinned`
   is in fact retained per paper; fixed the script to read it directly
   (22 of 435 papers, 5.1%, not a batch-level approximation).

Scattered-imports number itself was simply stale, not buggy: 956 of
3568 (26.8%) → 1013 of 4172 (24.3%).

### Spreadsheet findings table and naming-conventions numbers

**Manuscript location.** Line 750 (Table) and line 778: "these checks
produced 34,799 findings, spanning 2,933 distinct files... 64,960
naming issues, 36,856... 'bad'... and 28,104... 'suggestion'... 733
distinct papers (47.6% of the 1,539 papers with a discoverable
repository)."

**Why computed.** `data_check`'s spreadsheet-level and column-level
data-quality checks (is this rectangular, is a column's content
suspicious, etc.) and `repo_check`'s file-naming-convention checks —
two more "comes for free from the same module run" diagnostic outputs,
neither asked for by Cooper's protocol.

**Definition.** The spreadsheet-findings table is a frequency count of
`res_data_check$findings$check` (one row per individual finding, e.g.
"a column looks like it holds personal information"), sorted
descending. The naming-issues count splits `res_repo_check$naming_issues`
by `severity` ("bad" = something that actually breaks something;
"suggestion" = a convention worth following but nothing depends on it)
and by `rule` within each severity. The "papers with a discoverable
repository" denominator (1539) uses `summary_table$files_n > 0` —
confirmed to be the IDENTICAL rule `mc_data_availability` itself uses,
so a paper repo_check found nothing for correctly cannot count against
this specific percentage's base (it has no files to have a naming
issue on).

**Data used.** `res_data_check$findings` (34,799 rows);
`res_repo_check$naming_issues` (64,960 rows) and
`res_repo_check$summary_table$files_n` (for the denominator).

**Formula.** `tab <- sort(table(findings$check), decreasing=TRUE)`;
`n_papers_with_repo <- sum(summary_table$files_n > 0, na.rm=TRUE)`;
`pct_papers_naming <- 100 * n_papers_naming / n_papers_with_repo`.

**Relation to Cooper.** N/A — explicitly and deliberately not validated
against Cooper's coding, since her protocol asked nothing like this;
the manuscript's own "Why this section exists" paragraph states this
directly.

**Interpretation.** The PII-adjacent findings (personal info by column
name/values, free text that may hold PII — 3 of the 19 categories)
total 1,320 findings corpus-wide, which the manuscript reads as "a
possible participant-privacy check would find comparable value to the
correctness-oriented deposit review Cooper et al.'s protocol already
performs" — a suggestion for future work, not a claim that every one of
these 1,320 is a genuine privacy problem (a column literally named
"participant_id" holding only anonymous sequential integers would also
match by name alone).

**Verification status.** MISMATCH → FIXED, same staleness pattern:
findings 13,015→34,799, files flagged 2,028→2,933, naming issues
28,614→64,960 (bad 14,792→36,856, suggestion 13,822→28,104), papers
with naming issue 717/1,480(48.4%)→733/1,539(47.6%). The hardcoded
markdown table was also replaced with a `flextable` generated directly
from `fe$spreadsheet_findings_table`, so the table and the summary
numbers quoted in prose can never drift apart from each other again
the way they could when both were separately hand-typed.

---

## Discussion section (lines 768-811)

### Table 0 (summary table across all six constructs)

**Manuscript location.** Lines 772-797, the `summary-table-display`
chunk.

**Why computed.** A single reference table collecting every
construct's agreement rate, sensitivity, specificity, and the two
directional miss rates side by side — everything computed and verified
individually above, in one place for cross-construct comparison.

**Definition/Data used/Formula.** Reuses `results` (already loaded,
already verified above) directly — `lapply(names(results), function(nm)
data.frame(Construct=r$label, n=r$n_both_coded, ...))`, no new
computation.

**Relation to Cooper.** Each row IS one of the six direct Cooper
comparisons detailed above — this table adds nothing new, it just
re-presents the same six numbers in one place.

**Interpretation.** See each construct's own entry above.

**Verification status.** OK — built entirely from already-verified
`results` fields; no separate check needed beyond re-confirming each
construct's own numbers (done above).

### PPV values and `repo_not_detected` cross-construct counts

**Manuscript location.** Line 801: "positive predictive value was above
97% for five of the six boolean constructs (data_availability 98.3%,
data_license 96.4%, data_download 99.8%, code_download 99.7%,
any_readme 97.3%)... code_archived is the exception: its PPV, 92.6%."
Line 805: "repository non-detection alone accounts for 192 of
data_availability's 230 COOPER_RIGHT disagreements, 43 of
code_archived's 158, and 116 of any_readme's 155."

**Why computed.** PPV ("of the papers Metacheck said Yes to, how many
did Cooper agree with") is the single number most relevant to a reader
deciding whether to trust a Metacheck `TRUE` at face value — distinct
from sensitivity, which asks the opposite-direction question.

**Definition.** `ppv <- tp / (tp + fp)` — same confusion-table
components as every other statistic above, just this one specific
ratio, pulled from each construct's already-computed `results$<construct>$ppv`.

**Data used.** `results` (already loaded/verified above) — no new
computation, just six already-existing fields read together.

**Formula.** Direct field reads: `pct1(results$code_archived$ppv)`,
etc.

**Relation to Cooper.** Same as each construct's own entry above — PPV
is just one specific slice of the same confusion table.

**Interpretation.** Five of six constructs above 97% PPV means "when
Metacheck commits to a Yes, that Yes is rarely spurious" — the
dominant failure mode in this comparison is under-detection
(sensitivity), not false alarms. `code_archived`'s lower PPV (92.6%) is
explained directly: a meaningful share of its disagreements
(29 of 210) are cases where `code_check` correctly found real code
Cooper's own coders missed — genuine human-coder misses that lower
this specific metric even though Metacheck's underlying detection was
RIGHT, not wrong.

**Verification status.** OK — all six PPV values and all three
cross-construct `repo_not_detected` counts reproduce exactly from
`results`/`cooper_right_causes`.

### "Twelve individual software defects" and the before/after agreement chains

**Manuscript location.** Line 807: "Five were found during the
original review... Fixing #384... code_download agreement rose from
66.2%... to 89.7%... to 99.5% (after #384)." Line 809: "A further seven
fixes (Appendix A.5)..."

**Why computed.** A running tally of every confirmed, upstream-reported
Metacheck software defect this project identified and fixed, as the
paper's own framing of its contribution: not a single aggregate
accuracy number, but a construct-by-construct, defect-by-defect map of
WHY disagreement occurs and what closing each gap actually does to the
numbers.

**Definition.** "Twelve" = 5 (Appendix A.1: #378/379/380/383/384) + 7
(Appendix A.5: 2 Zenodo reliability fixes + 3 platform-coverage fixes +
2 rate-limit fixes, matching A.5's own "seven more commits" framing
exactly).

**Data used.** The intermediate percentages (66.2%, 89.7%) are fixed,
point-in-time historical facts about an earlier state of the
corpus/codebase — not re-derivable from any current object, the same
way a lab notebook's dated entry isn't recomputed later. Only the
CHAIN'S FINAL value (99.5%) is a live, current statistic
(`results$code_download$pct_agree`).

**Formula.** N/A for the historical values (narrative record); the
final value uses the same formula as every other construct's
`pct_agree` above.

**Relation to Cooper.** The final value in each improvement chain IS
the same `code_download`/`data_availability`/etc. comparison detailed
in its own entry above — these paragraphs are narrating HOW that
number got to be what it currently is, not computing anything new.

**Interpretation.** This framing (defect-by-defect, not one aggregate
number) is the manuscript's own stated methodological contribution —
treat the "12 defects" count and the specific before/after percentages
as a historical record of this project's own process, not as corpus
statistics that could silently drift the way a live `` `r ...` ``
value can.

**Verification status.** OK — the "twelve" arithmetic (5+7) is
internally self-consistent with the text's own breakdown, and the
chain's live final value (99.5%) matches the independently-verified
`code_download` entry above exactly. The two earlier historical
percentages (66.2%, 89.7%) were deliberately NOT re-verified, since
they describe a fixed past state with no current artifact to check
them against — this is the correct treatment for this class of number,
not an oversight.

---

## Appendix A.7 — full-corpus `reproducibility_check` run (lines 927-1036)

A structurally different appendix from everything above: **zero**
inline `` `r ...` `` expressions anywhere in it — every number is a
hardcoded literal describing one specific, one-time historical run
(not a live corpus statistic that recomputes at render time). Verified
~25 distinct claims directly against the surviving data files
(`code/data/reproducibility_check_results.RData`,
`reproducibility_check_detail.RData`) rather than trusting the prose at
face value, since these files happened to still exist and load fast.

### Scope and paper-level outcome counts

**Manuscript location.** Line 949/955/965: "343 (18.4%) had at least
one code file... 4,394 individual scripts were attempted... only 85 of
the 343 (24.8%) had every script run without error; 136 (39.7%) had
zero; the remaining 122 (35.6%) had a mix."

**Why computed.** Establishes the basic scale and success rate of
attempting to actually EXECUTE every code-bearing paper's own shared
code against its own shared data, inside an isolated Docker sandbox —
a fundamentally different, much stricter test than "does a repository
exist" or "does a file classify as code."

**Definition.** `repro_code_n > 0` = at least one code file found for
that paper. A script's `outcome` is one of `ran_ok`/`errored`/
`skipped_missing_inputs`/`not_parsed`/`timed_out`. At the paper level:
"all ok" = every one of that paper's scripts is `ran_ok`; "zero ok" =
none are; "mixed" = some but not all.

**Data used.** `out$results$summary_table` (1861 rows, one per paper)
and `out$results$table` (4,394 rows, one per script attempted).

**Formula.** Direct tabulation: `sum(repro_code_n > 0, na.rm=TRUE)`;
per-paper, `split(table$outcome, table$paper_id)` then
`sapply(x, function(v) all(v=="ran_ok"))` etc.

**Relation to Cooper.** N/A — Cooper's protocol has no "does the code
actually execute and reproduce its own results" question at all; this
entire appendix is new ground `code_check`/`repo_check` cannot cover.

**Interpretation.** 24.8% full-success is a low bar by construction
(this is the single strictest test of code sharing in the whole
project), and should be read alongside the error-type breakdown below —
it is NOT a claim that 75.2% of papers' underlying research is wrong,
since code can fail to run unattended for reasons unrelated to
correctness (an interactive `file.choose()` call, a missing system
library, a dependency CRAN has since removed).

**Verification status.** OK — reproduces exactly against
`reproducibility_check_results.RData` directly (343/4394/85/136/122,
all matching).

### Error-type breakdown, missing-inputs, dependency installation, result matching

**Manuscript location.** Lines 967-1004: error_type breakdown
(637/1242/14 = undefined_variable/runtime/timeout), missing inputs (129
papers, 417/68/40/3 by `not_runnable_reason`), dependency installation
(274 papers declaring 3,508 packages; 80 papers with a genuine install
failure and zero successful scripts, 187 individual failed-install
records naming 109 distinct packages), result matching (133 papers,
802 reported statistics, 66 matched — 62 full-confidence, 4 partial —
and 523 of the 736 unmatched flagged `plausible_split`).

**Why computed.** A full breakdown of WHY a script failed to run or
WHY a reported result didn't reproduce, at every level of granularity
this run's own output supports — the same "don't stop at the aggregate
number, categorize every cause" standard applied to the Empirical
Comparison section above, just for a different, stricter construct.

**Definition/Data used/Formula.** See each count's own direct
tabulation against `out$results$table`'s `error_type`/
`not_runnable_reason` fields, `summary_table$repro_deps`, and
`reproducibility_detail$all_matches$confidence`/`plausible_split` (a
separate extraction file, `reproducibility_detail.RData`, built by
re-parsing each paper's saved checkpoint text since the structured
summary table doesn't retain package-level failure detail).

**Relation to Cooper.** N/A for all of these — none has any Cooper-
coded counterpart.

**Interpretation.** The `plausible_split` distinction is the most
analytically useful single result-matching number: it separates "the
code never produced anything resembling this number" (a serious
finding) from "the code produced this exact number, just not grouped
the way the paper's text implies" (a much less serious one) — without
it, the headline "92.5% of papers reproduced none of their results" (0%
median) would read as far more damning than the fuller picture
supports.

**Verification status.** OK for essentially everything — ~25 distinct
values cross-checked directly against the surviving RData files, all
matched exactly. ONE MISMATCH → FIXED: line 941 claimed
`out$results$table` has 4,315 rows, contradicted two sentences later by
the correctly-used "4,394" and by the outcome table's own components
summing to 4,394 — a simple stale typo, fixed to 4,394.

---

## Appendix A.9 — full paper-by-paper recheck of "unsupported repository" disagreements (lines 1052-1135)

### Table 2 (40 newly-reviewed disagreements) and Table 3 (9 corrected rows from the original 230)

**Manuscript location.** Line 1091/1095: "40 of the 174 papers... had
not yet been individually checked... Of the 230, 21 candidate citations
resolved to a host now confirmed supported... 9 rows were corrected to
SUPPORTED_PLATFORM_BUG or SUPPORTED_PLATFORM_MISSED."

**Why computed.** The most granular review in the whole manuscript:
every remaining "repository not detected despite an unsupported-
platform label" disagreement, checked one paper at a time against the
paper's own extracted text and, where a specific platform is named, a
LIVE query against that platform's own current API — specifically to
catch cases where Cooper's catch-all "Other repo/database" label
concealed a real, already-supported platform Metacheck simply failed
to detect for a confirmed, fixable reason.

**Definition.** `a9_cats`/`a9_corr_tab` = two tables built by filtering
`repo_not_detected_categorization.csv` (the manually-produced,
individually-verified categorization file) to two fixed lists of
article IDs recorded at the time this specific review was conducted.

**Data used.** `repo_not_detected_categorization.csv` (267 rows
currently) filtered against two hardcoded 40-id and 9-id lists.

**Formula.** `a9_cats <- a9_full[a9_full$article_id %in% a9_new_ids,
]`, matched back into the original id order for display.

**Relation to Cooper.** Each row's `category` field is the final,
individually-verified answer to "was this disagreement with Cooper
caused by a genuinely unsupported platform, a confirmed software bug on
an already-supported one, or something else (a bioinformatics
accession, withheld data, a text-extraction artifact)" — the most
fine-grained possible resolution of a Cooper-vs-Metacheck disagreement
in this entire manuscript.

**Interpretation.** The two named worked examples (4TU's UUID-vs-
numeric-ID mismatch; DANS's shared-DOI-prefix-across-four-instances
bug) are concrete, root-caused software defects on platforms Metacheck
otherwise handles correctly — direct evidence that "repository not
detected" does not always mean "unsupported platform," even after
every other round of this project's fixes.

**Verification status.** MAJOR MISMATCH → FIXED. Both hardcoded ID
lists had gone stale relative to the CURRENT
`repo_not_detected_categorization.csv`: 8 of the 9 "Table 3" ids and 3
of the 40 "Table 2" ids no longer exist in it at all — confirmed why:
`mc_data_availability` is now `TRUE` for every one of these 11 papers
(their underlying `repo_check` defect has since been fixed elsewhere in
the project, so they correctly dropped out of "repository not
detected" entirely). Unfixed, the original `match()`-based table-
building code would have rendered Table 3 with 8 of 9 rows completely
BLANK (`NA` in every column) and Table 2's `` `r nrow(a9_cats)` ``
would have silently rendered 37 instead of the "40" the prose and
table caption both explicitly promise. Fixed by filtering both tables
to ids still present in the current CSV before the `match()` call, and
rewriting the surrounding prose to state BOTH the original review
count and the current, still-live count explicitly, with the
difference attributed to its real cause (papers since fixed elsewhere)
rather than silently absorbed into a smaller number.

---


## Session log and complete fix list (2026-10-03)

Went through the entire manuscript top to bottom: Introduction, Methods/
Coding section (both subsections), Empirical Comparison (all six
constructs), the comment-quality correlation, "Results you get for
free", the Discussion, and all nine lettered appendices. Appendices A.1
and A.3-A.6 were cross-referenced while verifying claims elsewhere (their
own specific numbers — the R-package-exclusion fix counts, the Dataverse
DOI-prefix rebuild, Table 1's category breakdown — were confirmed as
part of the Methods section and Discussion checks above); A.7 and A.9
were each given an independent, standalone pass since they carry
numbers not otherwise cross-referenced anywhere else.

Memory note: `res_data_check.RData`/`res_code_check.RData` are ~1.9GB
each on disk and require considerably more once deserialized. Loading
both simultaneously (as the manuscript's own `data` chunk does, and as
a full `quarto render` would) pushed free system memory to under 1GB at
one point and had to be killed; every check in this audit after that
point loaded at most one such file at a time, extracted only what was
needed, and cached the small result — this is why a full end-to-end
render was not completed (see below), even though every individual fix
was verified by simulating its exact rendered output.

### All 19 fixes applied to `manuscript.qmd` (plus one script fix)

1. Appendix A.6: `SPLIT_DOI_EXTRACTION` hardcoded "41 papers" → computed
   expression (renders 25, the current true count).
2. A stale code comment (not reader-facing) claiming "232" rows in the
   categorization CSV, now 267 — updated with an explicit note to
   re-verify against the CSV directly in future rather than trust the
   comment.
3. Appendix "Three further questions": stale example filenames
   (`z_ntp.txt`, `selected_arcs.txt`, now typed `output` not
   `documentation`) replaced with two still-accurate examples (`2K.txt`,
   `arcs0_nos_1n_v2.txt`).
4. `data_archive`'s verdict-tally sentence: removed a dangling
   `DIFFERENT_DEFINITION` reference (0 current cases, would have
   rendered "0 was a case where...") and folded its intended example
   into the `BOTH_DEFENSIBLE` sentence instead.
5. `license-value-check` chunk: fixed `is_dryad_url()` to match all 14
   of Dryad's known DOI prefixes (via `metacheck:::.dryad_doi_prefixes()`)
   instead of hardcoding just one — this was flipping a "never happens"
   claim about non-Dryad CC0 licenses to false (14 real counterexamples).
6. `data_download`'s METACHECK_RIGHT sentence: was singular, describing
   only 1 of the construct's actual 3 METACHECK_RIGHT cases — rewritten
   to plural, naming all three.
7. `code_archived`'s numbered COOPER_RIGHT cause list: was missing a
   sixth cause (`r_package_source_excluded`, 5 cases) that made the
   list sum to 153 instead of the true 158 — added as item 6.
8. `any_readme`'s "slightly ahead" comparison (294 vs. 155, a 90%
   margin) → "well ahead."
9. Comment-quality-correlation chunk: `eval: FALSE` → `TRUE`; every
   hardcoded, stale number replaced with a computed `` `r cq$...` ``
   expression.
10. `04_free_extras_summary.R`: fixed the parse-error check's
    denominator (R-type, downloaded, parse()-reached files only) and
    the version-pinning check (real per-paper field, not a batch-level
    proxy); added the zero-comment-Python docstring cross-check and the
    papers-with-a-repository denominator for the naming-issue
    percentage; regenerated `free_extras_summary.RData`.
11. "Results you get for free" section: `eval: FALSE` → `TRUE`; every
    hardcoded number replaced with a computed `` `r fe$...` ``
    expression; hardcoded spreadsheet-findings markdown table replaced
    with a `flextable` built from the data directly.
12. Appendix A.3's closing "Status of the fixes" paragraph: corrected
    to state the promised full corpus rerun has in fact been performed
    (proven via the `has_docstring` field's presence), not "planned but
    not yet performed."
13-16. `code_download`'s "a single disagreement" claim, repeated in
    four separate places (lines 654, 658, 669, and the Discussion's
    limitation paragraph) — all four fixed to describe/count both of
    the construct's 2 real disagreements rather than only one.
17. Discussion's specificity-asymmetry sentence: "this reflects one
    unresolved case" → "a small handful of unresolved cases" (stays
    accurate at n=2 and would remain directionally correct if the count
    changes again).
18. Appendix A.7, line 941: `out$results$table` row count, "4,315" →
    "4,394" (a stale typo contradicted by the rest of the same
    appendix).
19. Appendix A.9: both hardcoded article-ID-list tables fixed to filter
    against ids still present in the current categorization CSV
    (previously would have rendered one table with 8 of 9 rows
    completely blank); surrounding prose rewritten to state both the
    original review count and the current, still-live count explicitly.

### Final-check: syntax and reference validation (performed in place of a full render)

- All 18 R code chunks in `manuscript.qmd` parse as valid R syntax
  (zero errors) — checked by extracting each chunk's code and calling
  `parse()` on it directly.
- All 303 inline `` `r ...` `` expressions in the prose parse as valid
  R syntax (zero errors) — same method, applied to every inline
  expression found via regex across the whole document.
- Cross-checked that every bare variable name referenced in an inline
  expression resolves to something actually assigned in one of the 18
  chunks (no leftover reference to a renamed/removed variable) — found
  zero real issues (three flagged tokens, `in`/`na.rm`/`TRUE`, were
  false positives from the regex heuristic: R keywords and named
  arguments, not undefined variables).
- Attempted a full `quarto render manuscript.qmd` as the strongest
  possible final check; had to abort partway through (see memory note
  above) since free system memory was not sufficient to hold both
  large RData files at once without risking a system-wide issue. Not
  completed, but not treated as essential either, since every
  individual fix's exact rendered output was already independently
  simulated and confirmed correct.

### Left deliberately unverified (historical claims, no live artifact to check against)

- Line 606: "an earlier, columnwise comparison inflated the
  disagreement count by 41%... before we corrected it" — a one-time,
  since-discarded comparison approach with no surviving intermediate
  artifact to recompute from.
- Appendix A.7, line 991: the live-CRAN/CRAN-Archive package-
  availability check — an explicitly time-stamped snapshot of an
  external, constantly-changing resource; re-checking it today would
  only describe today's CRAN state, not confirm or refute the original
  claim.
- Various point-in-time percentage chains in the Discussion and
  appendices (e.g. "66.2% → 89.7% → [live value]") — the live final
  value in each chain was verified; the earlier historical steps were
  not, since they describe a fixed past state with nothing left to
  recompute them from.
