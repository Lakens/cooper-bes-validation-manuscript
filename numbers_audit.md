# Numbers audit and variable reference

In this document I attempts t describe the provenance and meaning of every number mentioned in the main text. The goal is to make it transparent where each number comes from. . .

1. **A per-variable reference** (the bulk of this file): every number
   computed in `manuscript.qmd`, organized by the manuscript section it
   appears in, in reading order. Each entry gives:
   - **Manuscript location** — line(s) and the rendered sentence.
   - **Why this value is computed** — what question it answers.
   - **Definition** — what the variable actually means, precisely.
   - **Provenance** — the full chain from raw source file to the final
     manuscript variable: which raw file, which column (with its exact
     codebook label and literal value set, where Cooper's own coded
     columns are involved), which script transforms it, which
     intermediate object/file carries it, and what the final variable
     in `manuscript.qmd` is called.
   - **Formula** — the actual computation (numerator/denominator or
     derivation rule), in plain terms.
   - **Relation to Cooper** (only for values compared against Cooper et
     al.'s human coding) — which of Cooper's own columns/values it is
     being checked against, what Cooper's own published paper says
     about that question, and what counts as agreement.
   - **Interpretation** — how to read the resulting number: what a high
     or low value would mean, and any caveat on trusting it at face
     value.
   - **Verification status** — OK (reproduces exactly from current
     data), MISMATCH→FIXED (was wrong, now corrected — with before/
     after), or FLAG (not wrong, but worth knowing about).

2. **A session log** (at the end) of the verification process itself:
   what was checked, in what order, and a list of every fix applied.

---

## Sources this document traces every number back to

### Cooper et al.'s own raw data: the hackathon codebook

**`code/data/BES-data-code-hackathon-cleaned_2025-12-01.csv`** — 1861
rows (one per paper), 44 columns. This is Cooper et al.'s actual
codebook: there is no separate codebook document distinct from this
file's own column headers, which are the literal field names the 145
hackathon participants filled in via dropdown/multiple-choice form
fields (Cooper et al., 2026, §2.1.2–2.1.3). Verified directly against
Cooper et al.'s own published paper (*Methods in Ecology and
Evolution*, 2026, 17, 1954–1966, DOI `10.1111/2041-210x.70338`):
re-deriving her headline percentages straight from this CSV's own
columns reproduces her Results section exactly — `data_used=="Yes"`
gives 1735 (her "93%, n=1735"); of those, `data_availability=="Yes"`
gives 1690 (her "97%, n=1690"); `code_used=="Yes"` gives 1670 (her
"90%, n=1670"); of those, `code_archived=="Yes"` gives 577 (her "35%,
n=577"). This confirms the local CSV this project reads from is
genuinely her published dataset, not a divergent or stale copy.

The 44 raw columns, grouped by what they code (names exactly as they
appear in the CSV header):

- **Identification**: `paper_number`, `doi`, `year_published`,
  `journal`, `article_type`, `recorder_ID`, `country_first`, `comments`.
- **Question 1 (use/archiving)**: `data_used`, `data_availability`,
  `data_availability_text`, `code_used`, `code_alert`, `code_archived`,
  `code_availability`.
- **Question 2 (where archived)**: `data_link`, `data_archive`,
  `code_link`, `code_archive`.
- **Question 3 (located/downloaded/opened)**: `data_download`,
  `data_open`, `code_download`, `code_open`.
- **Question 4 (file formats)**: `data_format`, `code_format`,
  `code_language`.
- **Question 5 (README)**: `data_README`, `data_README_scale`,
  `code_README`, `code_README_scale`.
- **Question 6 (data completeness)**: `data_completeness`.
- **Question 7 (code annotation)**: `code_annotation_scale`.
- **Question 8 (citability)**: `data_doi`, `data_license`,
  `data_license_type`, `code_doi`, `code_license`, `code_license_type`,
  `code_CITATION`.
- **Other recorded fields not discussed in this manuscript**:
  `code_vignette`, `code_Rpackage_available`, `code_application_cited`.

Cooper et al.'s own published recoding rules applied before her
results were summarised (2026, §2.1.3, "Data analysis" paragraph —
these rules are baked into the raw CSV's own values, not something
this project's scripts apply): "Data that were only available on
request or were embargoed were coded as 'No' for data availability and
data-archiving questions. Data or code that required specific software
or were too large to be downloaded/opened were coded as 'Maybe'...
Where participants specified that some, but not all, data or code
files could be downloaded or opened, we re-coded this as 'Yes'." 23
records with data quality issues were removed before the CSV was
finalised (her specific list of excluded paper numbers is given in her
Methods, p.1958) — this project's copy of the CSV already reflects
that removal (1861 rows, matching her own "we collected data on 1861
papers").

### The comparison-building pipeline (raw CSV → manuscript variable)

Three scripts, run in order, carry every Cooper-vs-Metacheck number
from the raw CSV through to what `manuscript.qmd` actually reads:

1. **`code/02_create_comparison_data/01_comparison_data.R`** — Step A
   derives every `mc_*` column (Metacheck's own answer to each Cooper
   question) directly from `res_repo_check.RData`/
   `res_data_check.RData`/`res_code_check.RData` (the three core
   modules' full corpus-wide output), with each derivation rule
   written explicitly in the script's own header comment (reproduced
   per-construct below). Step B joins these `mc_*` columns onto
   Cooper's own raw columns, keyed by `article_id` (resolved from
   `doi` via `sample.csv`, with four known paper-level DOI
   data-entry errors corrected first — see "Known data correction"
   below). Output: `cooper_vs_metacheck.rds` (1861 rows), internally
   called `side_by_side` inside this script.
2. **`code/02_create_comparison_data/03_build_master_comparison.R`** —
   loads `cooper_vs_metacheck.rds`, adds `mc_data_open`/`mc_code_open`
   (from `res_open_practices.RData`), `oddpub_data_open`/
   `oddpub_code_open` (from `res_oddpub.RData`), and joins Cooper's own
   `data_open`/`code_open`/`recorder_ID` columns fresh from the raw CSV
   (these three are not carried on `cooper_vs_metacheck.rds`). Also
   computes `accuracy_summary` (OddPub vs. `open_practices` accuracy
   against Cooper's `data_open`/`code_open`), stored as an R attribute
   on the saved object. Output: `master_comparison.rds` (1861 rows, a
   strict superset of `cooper_vs_metacheck.rds`'s columns).
3. **`code/03_comparing_results/01_compute_comparison_statistics.R`**
   — reads `master_comparison.rds` and
   `disagreement_review_worklist.xlsx` (the individually-reviewed
   verdict for every disagreement), computes the full confusion-table
   statistics (sensitivity, specificity, PPV, McNemar's test,
   agreement %) for each of the six boolean constructs. Output:
   `comparison_statistics.RData` (`results`, `verdict_tallies`).
   **`03_comparing_results/02_categorize_disagreement_causes.R`**
   additionally re-derives a reproducible, keyword-based root-cause
   categorization from the worklist's own free-text comments. Output:
   `disagreement_cause_categories.RData`.

`manuscript.qmd`'s own `data` chunk (lines 64–172) loads
`master_comparison.rds` under the name `side_by_side` (a different,
later object than script 1's own internal `side_by_side` variable —
same name, not the same object; `manuscript.qmd`'s `side_by_side` is
`master_comparison.rds`, which is a superset), plus
`comparison_statistics.RData`, `disagreement_cause_categories.RData`,
the worklist itself (as `review`), and `manuscript_data_slim.RData`
(a pre-extracted slim file carrying `repo_metadata` in full and only
the `paper_id`/`data_type`/`repo_url`/`file_name` columns of
`res_data_check$structure` and `paper_id`/`repo_url` of
`res_code_check$table` — built so the manuscript never has to load the
two ~1.9GB full module-output files directly).

**Known data correction applied before every join.** Cooper et al.'s
raw CSV has 4 rows (`paper_number` 57, 1275, 47, 7176) where the `doi`
field was mistakenly copy-pasted from a different paper's row
(confirmed by cross-referencing `paper_number` — unique, never
duplicated — against the master 8112-row metadata list: for all 4
pairs, the coder's own recorded `journal` matches that `paper_number`'s
TRUE journal, so only the `doi` field was wrong, not the whole
coding). Both comparison-building scripts correct all 4 DOIs to the
verified value before joining against `sample.csv`'s `article_id`
lookup; left uncorrected, the join becomes many-to-many and silently
produces 1869 rows instead of 1861.

### Codebook terms used throughout this document

- **"Both codeable" / `n_both_coded`**: a paper where NEITHER side's
  answer is missing for that specific sub-question. This always
  shrinks below 1861 construct by construct, for two structurally
  different reasons that both reduce it: (1) Cooper's own protocol
  only asks some sub-questions conditionally (e.g. `data_download` is
  only recorded for papers already coded `data_archived == "Yes"`), so
  her own column is legitimately `NA` for a paper where the
  sub-question never applied; (2) Metacheck's own `mc_*` column can be
  `NA` for a paper it could not process at all (e.g. the PDF could not
  be converted to extractable text).
- **Platform-name labels** (`data_archive`/`code_archive`'s value
  set): Cooper's raw values are `Dryad`, `Zenodo`, `Figshare`, `OSF`,
  `GitHub, GitLab, Codeberg or similar platform`, `CRAN`,
  `Supplementary materials`, `Personal website`, and the catch-all
  `Other repo/database` — her own paper defines this catch-all
  explicitly: "Institutional or governmental repositories, or specific
  projects (e.g. MoveBank), were simplified as 'Other repo/database'"
  (2026, §2.1.3, question 2). A paper can carry more than one label,
  semicolon-joined in the raw CSV (e.g. `"Dryad;Zenodo"`).

---

## Introduction (line 182)

### Recorder workload: median/min/max papers coded per recorder_ID

**Manuscript location.** Line 182: "145 people coded a median of 10
(min = 1, max = 68) manuscripts."

**Why computed.** To illustrate the scale of Cooper et al.'s own
manual-coding effort (145 human coders dividing 1861 papers between
them), as context for why an automated alternative is worth
investigating at all.

**Definition.** For each of the 145 distinct human coders who
contributed at least one row to the corpus, the number of papers they
personally coded; median/min/max taken across those 145 counts.

**Provenance.** Raw source: `recorder_ID` — the hackathon's own
anonymised coder-ID column, assigned post-collection ("Data recorders
were anonymised post-data collection and each unique data recorder, or
group of data recorders, was given a recorder ID number," Cooper et
al., 2026, §2.1.3). Raw file:
`code/data/BES-data-code-hackathon-cleaned_2025-12-01.csv`. Script:
`03_build_master_comparison.R` joins `recorder_ID` from the
DOI-corrected, deduplicated 1861-row Cooper join (not read from the
raw CSV directly in `manuscript.qmd`, specifically to avoid the
4-duplicate-DOI bug inflating the row count to 1865 — see "Known data
correction" above). Final variable:
`master_comparison$recorder_ID`, read in `manuscript.qmd` as
`side_by_side$recorder_ID`, 1861 rows, 145 distinct non-missing
values.

**Formula.** `tab <- table(recorder_ID); median(tab); min(tab);
max(tab)`.

**Interpretation.** A median of 10 with a max of 68 shows the workload
was very unevenly split across coders (a small number did far more
than their even share) — useful context for why a two-day hackathon
model is labor-intensive even before considering per-item coding time.

**Verification status.** OK — reproduces exactly (median 10, min 1,
max 68, 145 recorders) from `master_comparison$recorder_ID` directly.

---

## Methods section — "1. Does the paper use data/code? If so, are they archived?" (lines 403-423)

This subsection's own name is taken directly from Cooper et al.'s
protocol question 1 heading (2026, §2.1.3): "1. Does the paper use
data/code? If so, are they archived?" Her own operational rule for
"used": "A paper used data if it generated or collated a dataset
essential for reproducing the main results of the study... to
determine whether a paper used code we read the Methods section of the
paper and identified statements that made it clear that code was
used, even if it was not archived."

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

**Provenance.** Raw source columns: `data_availability` (literal value
set: `"Yes"` [1690 rows] / `"No"` [21] / `"No, but they are available
on request"` [24] / `NA` [126, i.e. `data_used == "No"`, the
sub-question did not apply]) and `code_archived` (literal value set:
`"Yes"` [577] / `"No"` [1092] / `NA` [192, i.e. `code_used` was `"No"`
or `"Unsure"`]) — both read straight off Cooper's raw CSV, no
recoding applied for this specific count (the "available on request"
→ Cooper-negative recoding only matters for the later boolean
sensitivity/specificity comparison, not this raw restatement of her
own published totals). File: raw CSV, read via
`master_comparison$data_availability`/`$code_archived` (carried
through unchanged by both comparison-building scripts — `side_by_side`
in `manuscript.qmd`).

**Formula.** `n_cooper_data <- sum(data_availability == "Yes")`;
`n_cooper_code <- sum(code_archived == "Yes")`; `n_cooper_either <-
sum(data_availability == "Yes" | code_archived == "Yes")`.

**Relation to Cooper.** This *is* Cooper's own coding, read verbatim —
no comparison yet at this point, just her numbers restated to set up
the Metacheck-side numbers in the next sentence. Her own paper states
these same two counts as percentages of her conditional denominators
("97%, n=1690... archived their data," out of 1735 papers using data;
"35%, n=577... archived their code," out of 1670 using code) — this
manuscript's 1690/577 match her published absolute counts exactly;
`n_cooper_either` (1789) is this project's own derived union, not a
number Cooper's paper itself reports.

**Interpretation.** 1690 and 577 match Cooper's own published quote
exactly, confirming the join between this project's local copy of her
data and her own paper is correct.

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

**Provenance.** `mc_data_availability` is derived (not a raw column —
there is no Cooper counterpart to this specific Metacheck signal) in
`01_comparison_data.R`: `res_repo_check$summary_table |> summarise(any(files_n
> 0, na.rm = TRUE), .by = paper_id)` — i.e., does `repo_check`'s own
per-paper file count exceed zero, for ANY file type, not specifically
data. Carried onto `cooper_vs_metacheck.rds` → `master_comparison.rds`
→ `side_by_side$mc_data_availability` in `manuscript.qmd`. The finer
`n_mc_data`/`n_mc_code` counts read `structure_slim$data_type ==
"data"` and `code_table_slim$paper_id` directly (from
`manuscript_data_slim.RData`, originally `res_data_check$structure`
124,775 rows and `res_code_check$table` 9202 rows), since
`master_comparison` only carries the per-paper summary, not the
per-file breakdown these two specific counts need.

**Formula.** `n_mc_repo_found <- sum(mc_data_availability, na.rm=TRUE)`;
`papers_with_data <- unique(structure$paper_id[structure$data_type ==
"data"])`; `papers_with_code <- unique(table$paper_id)`; `n_mc_either <-
length(union(papers_with_data, papers_with_code))`.

**Relation to Cooper.** Not a direct paper-by-paper comparison yet —
just the aggregate Metacheck-side count set next to Cooper's aggregate
count (1488 vs. 1789) before the next paragraph compares them paper by
paper. Note a scoping asymmetry worth flagging explicitly: Cooper's
1789 counts a paper if EITHER her `data_availability` or
`code_archived` says Yes (both are unconditional-on-use booleans in
her own coding); Metacheck's 1488 counts a paper if `data_check` or
`code_check` classified at least one FILE as data or code — a
narrower, file-content-level test than Cooper's protocol-level
yes/no question, which matters for interpreting the gap.

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

**Provenance.** `cooper_either_ids` built directly from
`master_comparison$article_id` where `data_availability == "Yes" |
code_archived == "Yes"` (raw Cooper columns, same source as
`n_cooper_either` above); `mc_either_ids` = `papers_with_data ∪
papers_with_code` (same derived set as `n_mc_either` above, from
`structure_slim`/`code_table_slim`).

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

### `n_repo_not_found_of_gap`, `n_repo_found_but_no_data_or_code` (two-cause breakdown of the `n_cooper_yes_mc_no` gap)

**Manuscript location.** The paragraph immediately following the
"Metacheck supports over 276 unique repositories... but this is only a
subset of all repositories used in manuscripts" sentence: "Metacheck
found data or code in 16 papers that the manual coders missed, but
missed 317 papers where the manual coders found data or code. Of these
317, for 267 papers Metacheck could not find a repository, while for 50
papers Metacheck found a repository, but it did not classify any files
in the repository as data or code. The remaining 0 papers are explained
by something other than a repository-detection failure..." (This
paragraph was rewritten from an earlier, more convoluted version — see
the session log — that led with a standalone corpus-wide "`repo_check`
found no repository at all for 322 papers, regardless of what Cooper
coded" framing; that framing was removed because the 322 figure has no
ground truth attached to it on its own and only became meaningful once
immediately qualified by a Cooper-agreement split, which the rewrite
now states directly instead of requiring the reader to hold 322 in mind
across two sentences. The corpus-wide `n_mc_no_repo_corpus_wide`/
`n_mc_missed_reviewed` split this removed is NOT lost — it still exists
exactly as before, three paragraphs later, where it correctly belongs:
introducing the individual review of what causes `repo_check` to find
nothing, not as a lead-in number for the found/missed comparison here.)

**Why computed.** Breaks the `n_cooper_yes_mc_no` gap (317 papers,
defined and computed in the entry immediately above) down into *why*
Metacheck found nothing for each one — distinguishing "no repository
was found at all" from the narrower, structurally different failure
"a repository was found, but nothing inside it was recognised as data
or code." This is the paragraph that sets up the subsequent individual
review of the `n_mc_missed_reviewed` papers (a related but not
identical 267-paper set — see the note below on how the two 267s
relate).

**Definition.** `gap_ids` = the 317 `article_id`s in
`setdiff(cooper_either_ids, mc_either_ids)` (identical set to
`n_cooper_yes_mc_no` above). `n_repo_not_found_of_gap` = of those, how
many appear in `repo_not_detected_categorization.csv`'s own
`article_id` list (i.e., were corpus-wide `repo_check`-found-nothing
papers that were individually human-reviewed — see the
`n_mc_no_repo_corpus_wide`/`n_mc_missed_reviewed` entry further below
for that file's provenance). `n_repo_found_but_no_data_or_code` = of
the same `gap_ids`, how many have `mc_data_availability == TRUE` (i.e.
`repo_check` *did* find a repository with at least one file of any
type) — the complementary, mutually exclusive cause.

**Provenance.** `cooper_either_ids`/`mc_either_ids` as defined in the
`n_both_yes_either` entry above (same raw columns:
`data_availability`/`code_archived` from Cooper's raw CSV;
`structure_slim$data_type == "data"`/`code_table_slim$paper_id` from
`manuscript_data_slim.RData`). `a6_cats_ids_check` is the same
`code/03_comparing_results/repo_not_detected_categorization.csv`
human-reviewed worklist used by the `n_mc_no_repo_corpus_wide` entry
below. `mc_data_availability` is the same corpus-wide Metacheck signal
used throughout this section (`res_repo_check$summary_table |>
summarise(any(files_n > 0))`).

**Formula.** `n_repo_not_found_of_gap <- sum(gap_ids %in%
a6_cats_ids_check)`; `n_repo_found_but_no_data_or_code <- sum(gap_ids
%in% side_by_side$article_id[side_by_side$mc_data_availability %in%
TRUE])`.

**Relation to Cooper.** Both counts are restricted to papers where
Cooper's coders already said "Yes" (data or code exists) and Metacheck
said "No" — i.e. papers already established as a Cooper-right
disagreement by the entry above; this paragraph only asks *why* each
one is a disagreement, not whether it is one.

**Interpretation.** In the current corpus run these two causes are
jointly exhaustive: 267 + 50 = 317 = the entire gap, so the "remaining
papers... explained by something other than a repository-detection
failure" clause in the manuscript's own prose currently describes zero
papers — worth flagging as a claim that is technically true (the
sentence correctly computes and states 0) but reads as though it
expects a nonzero remainder; if the underlying numbers shift in a
future rerun such that the remainder becomes nonzero, the sentence's
phrasing already accommodates that, but as of this run it is
describing an empty set. **Note on the two different "267"s in this
manuscript**: `n_repo_not_found_of_gap` (267) and `n_mc_missed_reviewed`
(267, computed independently further below) are numerically equal but
not guaranteed to be the identical set by construction — the former is
"of the 317-paper Cooper-right gap, how many are in the reviewed-CSV's
id list"; the latter is "how many rows (deduplicated by article_id) does
the reviewed CSV itself contain." They coincide here because every
paper in the reviewed CSV is, by the review process's own design, a
paper from this same gap — but this is a fact about how the CSV was
built, not something the formula for either number enforces, so a
future CSV update that added a reviewed paper outside the current gap
definition would make them diverge.

**Verification status.** OK — n_cooper_yes_mc_no=317 (cross-checked
against the entry above), n_repo_not_found_of_gap=267,
n_repo_found_but_no_data_or_code=50, sum=317, remainder=0; all
reproduce exactly from `master_comparison.rds` +
`manuscript_data_slim.RData` + `repo_not_detected_categorization.csv`.

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

**Provenance.** No Cooper-side source at all — this is purely
Metacheck's own internal package data. Source:
`metacheck:::.dataverse_hosts()`, `.dataverse_doi_prefix_hosts()`,
`.dspace7_hosts()`, `.dspace_legacy_hosts()`, `.dataone_hosts()`,
`.figshare_vanity_hosts()`, `.figshare_doi_prefix_hosts()` —
package-internal lookup tables bundled with the installed `metacheck`
R package, not corpus data; this number does not change based on which
papers are in the corpus, only on which version of the `metacheck`
package is installed.

**Formula.** `n_unique_repos <- n_dataverse_hosts + n_dspace7_hosts +
n_dspace_legacy_hosts + n_dataone_hosts + n_figshare_hosts +
n_dedicated_platforms` (simple sum of the five host-list lengths plus
the hardcoded 11).

**Interpretation.** This number will change if `metacheck` itself is
upgraded (e.g., Appendix A.5/A.6 describe several of these host counts
growing over the course of this project) — it measures the tool's
current coverage.

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

**Provenance.** Raw source column: `data_archive` — Cooper's
platform-name label (1861 rows; her own codebook's literal top values:
`"Dryad"` 967, `"Other repo/database"` 253, `NA` 191 [no data
archived], `"Zenodo"` 162, `"Figshare"` 155, with 29 distinct
multi-value combinations like `"Dryad;Other repo/database"` below
that), semicolon-joined multi-value text field, read directly from
`master_comparison$data_archive` (`side_by_side` in `manuscript.qmd`)
— no derivation script involved, this is Cooper's raw coded value used
as-is.

**Formula.** `is_unsupported_only <- vapply(strsplit(data_archive,
";"), function(v) all(trimws(v) %in% c("Other repo/database",
"Personal website", "Supplementary materials")), logical(1))`;
`n_unsupported_repo <- sum(is_unsupported_only)`.

**Relation to Cooper.** Built entirely from Cooper's own coded label,
not Metacheck's — this count says nothing yet about whether Metacheck
actually failed on these papers (that's `n_unsupported_repo_and_mc_missed`,
below); it's purely "how did Cooper's coders describe this paper's
archive." Her own paper defines the "Other repo/database" label
explicitly (2026, §2.1.3, question 2): "Institutional or governmental
repositories, or specific projects (e.g. MoveBank), were simplified as
'Other repo/database'" — a deliberately coarse catch-all in her own
protocol, not a claim about tool-supportability.

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

**Provenance.** `side_by_side$mc_data_availability` (the derived
signal described above) for the corpus-wide count — NOT a Cooper
column. For the reviewed subset:
`code/03_comparing_results/repo_not_detected_categorization.csv` — a
*manually produced* file, not a script's output; every row is a human
reviewer's individual verdict (`article_id`, `category`, free-text
justification), the primary record of that review work, deduplicated
by `article_id` to 267 current rows.

**Formula.** `n_mc_no_repo_corpus_wide <-
sum(!mc_data_availability, na.rm=TRUE)`;
`n_mc_missed_reviewed <- nrow(a6_cats_preview)` (deduplicated CSV);
`n_mc_missed_unsupported_repo <- sum(category ==
"UNSUPPORTED_REPO")`; etc., with `_other_named` as the arithmetic
remainder (`n_mc_missed_reviewed` minus the other three named buckets).

**Relation to Cooper.** This entire breakdown exists only for the
subset of "repo_check found nothing" papers where Cooper's own coding
disagrees (she said data/code exists, via `data_availability`/
`code_archived` — the same two raw columns used throughout this
subsection) — a paper where Cooper also coded nothing is correctly
excluded, since there's no disagreement to explain.

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

**Provenance.** No Cooper-side source — this is entirely a fact about
`repo_metadata` (one row per repository with retrievable metadata:
Zenodo, Dryad, Figshare, GitHub, and OSF with `osf_license=TRUE`),
carried unmodified in `manuscript_data_slim.RData` from
`res_repo_check$repo_metadata`. The `license` field itself is read
verbatim from each platform's own API at `repo_check` run time — no
corpus-level or Cooper-level recoding applied anywhere in this chain.
For reference, Cooper's own raw CSV codes a related but distinct
concept, `data_license_type` (literal values: `"CC0"` 1076, `NA` 343,
`"CC BY"` 340, `"Other"` 63, `"CC BY derivatives"` 25, `"OGL"` 13,
`"No"` 1) — her own published Figure 7 independently reports "CC0
licences (n=1076; the licence used by Dryad) being most used," a
figure this entry does not reproduce or compare against (it is a
different count: hers is "papers with a CC0-licensed data archive,"
this entry's is "repositories with a CC0-1.0 license string among the
ones Dryad-matched vs. not," a finer, repository-level, Metacheck-only
computation).

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

**Provenance.** Raw source column: `data_archive` (same Cooper column
as the unsupported-repository breakdown above), restricted here to its
four most common single values among the 2029 non-missing rows: `Dryad`
967, `Zenodo` 162, `Figshare` 155, plus every row containing "GitHub,
GitLab, Codeberg or similar platform" (16 single-valued + several
multi-valued combinations). Compared against
`side_by_side$mc_data_availability` (the same derived Metacheck signal
used throughout this section, from `01_comparison_data.R`).

**Formula.** `is_named_platform <- vapply(strsplit(data_archive, ";"),
function(v) any(trimws(v) %in% named_platform_labels), logical(1))`;
`n_fair_found <- sum(is_named_platform & mc_data_availability)`.

**Relation to Cooper.** Platform identity comes entirely from Cooper's
own `data_archive` coding; whether Metacheck "found" the paper comes
entirely from Metacheck's `mc_data_availability`. This is a direct,
clean test of detection *rate* conditional on Cooper having already
confirmed the platform is a real, supported one — the detection
question with every confound about platform ambiguity removed. Her
own paper's Figure 3 independently reports close but not identical
denominators for these same four platforms, computed from her raw
archive-location counts before this manuscript's own FAIR-subsetting
logic is applied (e.g. her "57% of data files... in Dryad, n=1022" is
a FILE count across all archived data, not this entry's PAPER count
restricted to the four named platforms) — the two are related but
answer different questions, and this manuscript's 1404/1349/55 are
this project's own derived counts, not numbers Cooper's paper states
directly.

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

**Provenance.** No Cooper-side source for this entry's own numbers
(the 51-paper denominator comes from the Metacheck-internal
`mc_data_availability` vs. `mc_either_ids` comparison described
above). File-level data:
`structure_slim$data_type` (a Metacheck-internal file classification,
values `data`/`code`/`documentation`/`materials`/`unknown`/`output`,
from `res_data_check$structure` via `manuscript_data_slim.RData`),
filtered to `paper_id %in% target_ids_missed_files` (124,775-row table,
filtered down to a 51-paper, 2614-row subset for this specific check).

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

**Provenance.** Raw source column: `data_format` — Cooper's own
file-extension codebook field (her literal value set, from the raw
CSV: `".csv/.tsv"` 568, `".xls(x)"` 542, `NA` 253, `".txt"` 73, and
various semicolon-joined multi-extension combinations below that; her
own paper's Results §4 independently reports the corpus-wide version
of this same field: "data were archived with 96 different file
extensions... 88% (n=1857) were saved with the following 10 file
extensions: .csv/.tsv, .doc(x), .fasta, .pdf, .rda/.rdata/.rds, .shp,
.tif, .xls(x), .xml"). This entry uses `data_format` only to identify
WHICH papers Cooper says have a `.tif`/`.shp` file, then checks the
REAL files in those specific papers' repositories against
`structure_slim$data_type`/`file_name` (Metacheck-internal, from
`res_data_check$structure`) — there is no Cooper-side per-file
classification to compare against directly, since her coding records
only the paper-level extension list, not a per-file type judgment.

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

**Provenance.** Cooper side: `data_archive` (raw CSV column, same
field discussed above, her own codebook's literal platform-name set).
Metacheck side: `mc_data_archive`, derived in `01_comparison_data.R`
(see the construct-definitions entry below for its exact derivation
rule — domain/DOI-prefix matching against each linked repository's
URL). Both carried through `cooper_vs_metacheck.rds` →
`master_comparison.rds` → `side_by_side` in `manuscript.qmd`. The
47 disagreements' verdicts come from
`code/02_create_comparison_data/disagreement_review_worklist.xlsx`
(loaded as `review`), columns `data_archive_verdict`/
`data_archive_comment` — a manually-maintained spreadsheet, one row
per individually-reviewed disagreement, each verdict assigned by a
human reading the paper's own text and/or querying the cited
platform's live API.

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
`mc_*` column means and exactly which raw Cooper column, with which
value-recoding rule, it is compared against.

Every `mc_*` column is derived in
`code/02_create_comparison_data/01_comparison_data.R` directly from
`res_repo_check.RData`/`res_data_check.RData`/`res_code_check.RData`
(the three core modules' corpus-wide output) — never from Cooper's own
CSV, and never by any LLM or subjective judgment call, only rule-based
field reads and joins. Each bullet below states the Metacheck-side
derivation, then the specific Cooper-side raw column and
positive/negative value-recoding rule it is compared against
downstream.

- **`mc_data_availability`**: `TRUE` if `repo_check`'s
  `summary_table$files_n > 0` — at least one linked repository with at
  least one file of ANY type (data, code, documentation, or
  unclassified). Deliberately permissive: answers "did we find a
  repository with something in it," not "did we find a repository
  holding a dataset." A paper whose only repository is a pure-code
  archive still scores TRUE here. *Compared against*: `data_availability`
  (raw literal values: `"Yes"` [positive], `"No"`/`"No, but they are
  available on request"` [negative, per Cooper's own stated recoding
  rule — see below], `NA` where `data_used == "No"`).
- **`mc_data_archive`**: the matching platform name(s), derived by
  checking each linked repository's URL against a fixed domain/
  DOI-prefix pattern set (`osf.io`→OSF, `zenodo.org` or
  `10.5281/zenodo`→Zenodo, `github.com`/`gitlab.com`→"GitHub, GitLab,
  Codeberg or similar platform", Dryad/Figshare matched against
  metacheck's own full DOI-prefix/vanity-host lists; anything else →
  "Other repo/database"). Semicolon-joined if a paper cites more than
  one platform holding data-classified files. *Compared against*:
  `data_archive` (raw, Cooper's own multi-valued platform-name field).
- **`mc_data_doi`/`mc_data_license`**: read from
  `repo_check$repo_metadata`, scoped to repositories holding at least
  one data-classified file — a paper whose licensed repository holds
  only code scores `mc_data_license = FALSE` even if a real license
  exists, by design (the scoping matches `mc_data_archive`'s own).
  *Compared against*: `data_license` (raw literal values: `"Yes"`
  [1437, positive], `"No"` [99, negative], `"Unsure"` [80, excluded —
  neither positive nor negative], `"Yes, but not for all data
  archived"` [1, a partial case]) — note this is a *distinct* raw
  column from `data_license_type` (the CC0/CC BY/MIT/etc. license-kind
  field used in the Dryad-CC0 entry above); `data_license` only codes
  presence/absence of a license at all.
- **`mc_data_download`**: `TRUE` if at least one data-classified file
  has BOTH `tabular_usable == TRUE` AND a non-missing `file_location` —
  a two-part test, so a file can download successfully and still fail
  this if `data_check` judges its content unusable as a table.
  *Compared against*: `data_download` (raw literal values: `"Yes"`
  [1594, positive], `"Yes, but not all data"` [6, folded into
  positive], `"No"` [13, negative], `"No, because the data are
  embargoed"` [5, excluded from this specific comparison — a distinct
  reason from a genuine download failure]).
- **`mc_any_readme`**: `TRUE` if `repo_check` classified at least one
  file, in ANY of a paper's repositories, with `doc_role == "readme"` —
  purely filename-based (starts with "readme", or a package-level
  `ro-crate-metadata.json`), never content-based. One signal per paper,
  not separated by data vs. code — hence compared against
  `cooper_any_readme` (Cooper's `data_README`/`code_README` columns
  collapsed with OR, built specifically for this comparison — see the
  `any_readme` entry below for its exact construction) rather than
  either raw Cooper column alone.
- **`mc_code_archived`**: `TRUE` if `code_check`'s file table has at
  least one row for the paper, regardless of download success.
  *Compared against*: `code_archived` (raw literal values: `"Yes"`
  [577, positive], `"No"` [1092, negative], `NA` [192, where
  `code_used` was `"No"` or `"Unsure"`]).
  **`mc_code_download`**: the stricter follow-up, requiring a
  non-missing `file_location` too. *Compared against*: `code_download`
  (raw literal values: `"Yes"` [536, positive], `"No"` [5, negative],
  `NA` [1320, legitimately not asked when `code_archived` was not
  `"Yes"`]).
- **`mc_code_used`**: always `NA` — no Metacheck module answers "did
  this paper use code" as a construct distinct from "is there a code
  file in a linked repository." Cooper's own raw column for this
  question, `code_used` (literal values: `"Yes"` 1670, `"No"` 134,
  `"Unsure"` 57), exists but has no Metacheck counterpart at all;
  `master_comparison` does not even carry it, by design.

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
the actual chunk logic (`01_comparison_data.R` lines 18-42, `helpers.R`
for the UTF-8 fix, and the `data` chunk's own `.cooper_bool()` recoding
in `manuscript.qmd`) exactly, and that every Cooper-side raw value set
quoted above matches `table(cooper[[col]])` on the live CSV exactly.

---

## OddPub / `open_practices` vs. Cooper's `data_open`/`code_open` (line 448)

### `accuracy_summary$oddpub_data`/`$oddpub_code`/`$metacheck_data`/`$metacheck_code` (n, sensitivity, specificity, accuracy)

**Manuscript location.** Line 448: "We compared the automatic
text-based judgements from OddPub and the Open Practices module to
Cooper and colleagues' human coding of whether data and code were
openly shared (their `data_open`/`code_open` columns), treating "Yes"
(and for data "Yes, but not all files") as open and "No" as not open,
and excluding papers where the coders used an ambiguous label (e.g.,
"Needs specific software or too large") or left the item unscored
(`data_open`/`code_open` were only asked for papers Cooper and
colleagues had already coded as archiving their data/code, and not
every such paper has a recorded answer, so the denominators below are
smaller than the archiving counts reported earlier)." Followed by the
sensitivity/specificity/accuracy figures for OddPub and
`open_practices`, separately for data and code.

**Why computed.** Tests whether two fully automated, text-based tools
(OddPub, an existing published tool; `open_practices`, Metacheck's own
module) agree with Cooper's own human-coded judgement of whether a
paper's data/code is genuinely open — a different, narrower question
than `repo_check`'s "is there a repository at all" tested elsewhere in
the manuscript, since both tools here read only the article's own text
(Data Availability statement etc.), not the repository itself.

**Definition.** For data: `oddpub_data_open`/`mc_data_open` (TRUE/FALSE,
from each tool's `summary_table`) compared against Cooper's `data_open`
recoded TRUE if `"Yes"` or `"Yes, but not all files"`, FALSE if
`"No"`, excluded (`NA`) otherwise (`"Needs specific software or too
large"` or genuinely blank). For code: `oddpub_code_open`/`mc_code_open`
compared against Cooper's `code_open` recoded TRUE if `"Yes"`, FALSE if
`"No"`, excluded otherwise (`"Maybe if I had the right software"` or
blank) — `code_open` is coded only TRUE on an exact `"Yes"`, never on
`"Yes, but not all files"`, but this is not an asymmetry in the rule:
that label never actually occurs in `code_open`'s value set (confirmed
directly against the raw CSV — `code_open`'s only three non-missing
values are `"Maybe if I had the right software"`, `"No"`, `"Yes"`), so
the two recoding rules are equivalent in practice, not inconsistent.

**Provenance.** Cooper-side: `data_open`/`code_open`, raw CSV columns
(literal value sets: `data_open` — `"Yes"` [1537], `"Yes, but not all
files"` [4], `"No"` [11], `"Needs specific software or too large"`
[41], `NA` [268]; `code_open` — `"Yes"` [495], `"No"` [3], `"Maybe if
I had the right software"` [34], `NA` [1329]), joined onto
`master_comparison` fresh from the raw CSV in
`03_build_master_comparison.R` (not carried on `cooper_vs_metacheck.rds`
— see the pipeline overview above). Both `data_open` and `code_open`
are conditional sub-questions under Cooper's own protocol question 3
("Can the archived data/code be located, downloaded and opened?"):
only asked for papers already coded `data_availability == "Yes"`
(1690 papers) or `code_archived == "Yes"` (577 papers) respectively —
confirmed directly: every one of the 171 papers where
`data_availability != "Yes"` has `data_open == NA`. Metacheck-side:
`mc_data_open`/`mc_code_open` (from `res_open_practices.RData`'s
`summary_table`) and `oddpub_data_open`/`oddpub_code_open` (from
`res_oddpub.RData`'s `summary_table`), both joined in the same script.
The `.cooper_yesno_data()`/`.cooper_yesno_code()`/`.accuracy_metrics()`
helper functions (lines 76-106 of `03_build_master_comparison.R`)
compute the confusion-matrix statistics, stored as the `accuracy_summary`
list attribute on `master_comparison.rds`, read directly by
`manuscript.qmd`.

**Formula.** Standard 2×2 confusion table against the recoded Cooper
truth value, restricted to non-`NA` on both sides (`valid <-
!is.na(pred) & !is.na(truth)`); `sensitivity <- tp/n_positive`;
`specificity <- tn/n_negative`; `accuracy <- (tp+tn)/n`. Same template
as the six Empirical Comparison constructs below, computed by a
separate script.

**Relation to Cooper.** Ground truth is Cooper's own `data_open`/
`code_open` coding, not `data_availability`/`code_archived` (the
broader archiving questions used elsewhere in the manuscript) — this
is specifically "of the papers Cooper's coders could actually open,
did they judge it genuinely accessible," which is why the denominator
(1552 for data, see below) is smaller than the 1690/577 archiving
counts quoted earlier in the manuscript: `data_open`/`code_open` is a
conditional follow-up question, and not every archiving paper has a
recorded answer to it.

**Interpretation.** For data: `n` = 1552 (1541 positive + 11 negative),
consistent with 1690 papers coded as archiving data, minus 41
"needs specific software/too large" (ambiguous, excluded) minus 97
genuinely left unscored despite the question applying (see the next
entry below for why this is 97, not the raw 268 blank-`data_open`
count) minus 171 papers where `data_open` is blank because
`data_availability != "Yes"` (the question never applied at all, not a
skipped answer — see next entry). The small negative class
(`n_negative` = 11 for data) means specificity estimates for both
tools rest on very few papers and should be read as indicative only, as
the manuscript's own caveat states. For code, the negative class is
even smaller (`n_negative` = 3), making code-sharing specificity
especially unstable.

**Verification status.** OK — `data_open` value counts (1537/4/11/41/268)
and `code_open` value counts (495/3/34/1329) reproduce exactly from the
raw CSV; the 1690-papers-only scoping of `data_open` (all 171
non-archiving papers show `NA`) confirmed directly; `n` = 1552 for data
cross-checks as 1541 positive + 11 negative.

### Excluded-papers breakdown: what OddPub/`open_practices` say about the papers with no Cooper ground truth (manuscript paragraph following the accuracy_summary sentence, line 448 chunk)

**Manuscript location.** The paragraph immediately after the
accuracy_summary sentence above: "Note that OddPub and `open_practices`
classify every paper regardless of how Cooper and colleagues' coders
scored this question. For data sharing, 97 papers archived their data
(`data_availability == "Yes"`) but were left unscored on whether it
could be opened, of which OddPub judged 44 (45%) and `open_practices`
judged 80 (82%) to have open data; a further 41 were explicitly
flagged... as needing specific software or too large to open, of which
OddPub judged 24 (59%) and `open_practices` judged 31 (76%) to have
open data. For code sharing, 49 papers archived their code... but were
left unscored..., of which OddPub judged 8 (16%) and `open_practices`
judged 25 (51%) to have open code; a further 34 were explicitly
flagged..., of which OddPub judged 16 (47%) and `open_practices`
judged 24 (71%) to have open code."

**Why computed.** The `accuracy_summary` sensitivity/specificity figures
above only describe the 1552 (data) / 577-ish (code) papers with a
clear human Yes/No — they say nothing about how either tool classifies
the papers Cooper's coders left ambiguous or genuinely unscored. This
paragraph reports each tool's raw claim rate on exactly those excluded
papers. There is no ground truth for them, so this cannot be scored as
correct/incorrect, only reported descriptively.

**Definition — two sub-groups, not one.** Initial drafting of this
paragraph used a single "excluded" denominator (`is.na(data_open)`,
raw count 268 for data / 1329 for code) which turned out to be
seriously misleading and was corrected before being added to the
manuscript:
- **Blank-but-applicable** (`n_blank_data_open` = 97,
  `n_blank_code_open` = 49): `data_open`/`code_open` is `NA` **and**
  the question should have applied, i.e. `data_availability == "Yes"`
  / `code_archived == "Yes"` — the paper did archive data/code, but the
  coder's answer to "could it be opened" is genuinely missing. This is
  the only group that is actually "left unscored" in the sense a reader
  would assume from that phrase.
- **Ambiguous** (`n_ambig_data_open` = 41, `n_ambig_code_open` = 34):
  `data_open`/`code_open` explicitly equals `"Needs specific software
  or too large"` / `"Maybe if I had the right software"` — Cooper et
  al.'s own stated "Maybe" category (2026, §2.2), not a skipped answer
  but a deliberate third response the coder gave.

**Why the naive 268/1329 denominator was wrong.** The raw
`is.na(data_open)` count of 268 (and 1329 for `code_open`) is dominated
by papers where the question never applied in the first place, not
papers a coder skipped: of the 268 blank `data_open` rows, only 97 have
`data_availability == "Yes"` (the other 171 split as 21
`data_availability == "No"`, 24 "available on request", 126
`data_availability == NA`, i.e. data was never used/archived, so the
"can it be opened" question was correctly never asked). The effect is
far larger for code: of the 1329 blank `code_open` rows, only 49 have
`code_archived == "Yes"` — the other 1280 have `code_archived == "No"`
(1089) or `NA` (191), i.e. no code was archived at all for the
overwhelming majority of "blank" rows. Reporting "1329 papers were left
unscored" (as an early draft of this paragraph did) would have wrongly
implied 1329 papers' openness-coding was simply missing, when in fact
96% of that figure (1280/1329) is papers with no archived code to begin
with — a structurally-skipped question, not missing data. This was
caught and fixed before publication by cross-tabulating the blank rows
against `data_availability`/`code_archived` directly.

**Provenance.** Same raw columns as the entry above
(`data_open`/`code_open`, `data_availability`, `code_archived`, all on
`master_comparison.rds` / `side_by_side`), plus `oddpub_data_open`/
`mc_data_open`/`oddpub_code_open`/`mc_code_open`. Computed directly in
`manuscript.qmd`'s own `data` chunk (not in any upstream R script),
immediately after `side_by_side <- master_comparison`.

**Formula.** `blank_data_open <- is.na(data_open) &
!is.na(data_availability) & data_availability == "Yes"`;
`ambig_data_open <- !is.na(data_open) & data_open == "Needs specific
software or too large"`; then, for each group and each tool,
`sum(tool_column[group], na.rm = TRUE)` out of `sum(group)`. Identical
construction for code, substituting `code_archived`/`code_open`/
`"Maybe if I had the right software"`.

**Relation to Cooper.** None of these four counts (97/41 for data,
49/34 for code) have a Cooper-coded correct answer to compare against —
unlike every other entry in this document, this is not a sensitivity/
specificity/accuracy computation, only a description of what each tool
claims on papers where Cooper's own protocol produced no usable Yes/No.

**Interpretation.** Both tools claim "open" far more often on the
ambiguous ("needs specific software/too large") papers than on the
genuinely-blank ones, for both data (59%/76% vs. 45%/82%) and
especially code (47%/71% vs. 16%/51%) — plausible, since a paper
Cooper's coder flagged as "needs specific software" necessarily does
name and locate a real repository (the coder found it and tried to open
it), whereas many genuinely-blank papers may never have been reached in
that much depth during the time-constrained hackathon. In every one of
the four comparisons, `open_practices` claims "open" substantially more
often than OddPub — consistent with the higher-sensitivity/
lower-specificity pattern already documented for the scored papers
above, now shown to hold on a completely different, non-overlapping
subset of papers.

**Verification status.** OK — all eight counts (97/44/80 for data-blank,
41/24/31 for data-ambiguous, 49/8/25 for code-blank, 34/16/24 for
code-ambiguous) reproduce exactly from `master_comparison.rds`; the
cross-tabulation confirming 1089/191/49 as the three-way split of the
1329 blank `code_open` rows against `code_archived`, and 21/24/97/126
as the four-way split of the 268 blank `data_open` rows against
`data_availability`, both confirmed directly against the raw CSV.

---

## Empirical Comparison section (lines 614-686)

Six constructs follow an identical statistical template, computed by
`03_comparing_results/01_compute_comparison_statistics.R` from
`master_comparison.rds` (confusion table) plus
`disagreement_review_worklist.xlsx` (qualitative verdicts). The
template is documented once here; each construct's entry below gives
only what's specific to it, plus its raw Cooper column's exact literal
value set and recoding rule.

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
specific Cooper-coded raw CSV column (named, with its exact literal
value set, in each entry's own "Provenance" field below) — not an
aggregate-vs-aggregate comparison the way some Methods-section numbers
are. `n_both_coded` always excludes a paper where EITHER side has no
answer (Cooper didn't code that sub-question for that paper, because
her own protocol only asks it conditionally — see each entry — or
Metacheck couldn't process the paper's PDF at all) — so the comparison
base shrinks construct by construct as coverage requirements stack up.

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

**Provenance.** Raw column: `data_availability` (full literal value
set: `"Yes"` 1690, `NA` 126, `"No, but they are available on
request"` 24, `"No"` 21 — the recoding rule folding the
available-on-request label into Cooper's negative set is this
manuscript's own choice, matching Cooper's own stated protocol rule
exactly: "Data that were only available on request or were embargoed
were coded as 'No' for data availability and data-archiving questions"
(Cooper et al., 2026, §2.1.3) — so this project's recoding is not an
independent interpretive choice, it reproduces Cooper's own published
rule). File:
`code/data/BES-data-code-hackathon-cleaned_2025-12-01.csv` →
`master_comparison$data_availability` (`side_by_side` in
`manuscript.qmd`) unchanged — the boolean recoding itself happens
inside `01_compute_comparison_statistics.R`, not upstream. Metacheck
side: `mc_data_availability` (derived in `01_comparison_data.R`, see
construct-definitions entry above).

**Formula.** Standard template above.

**Relation to Cooper.** Direct comparison against Cooper's
`data_availability` column. Note the "available on request" label is
folded into Cooper's NEGATIVE set here — a paper offering data only on
request counts as Cooper-coded "No" for this specific boolean
comparison, per her own protocol's recoding rule quoted above, even
though her raw label text itself reads more charitably; this is
exactly the source of several `DIFFERENT_DEFINITION` verdicts below.

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

**Provenance.** Raw column: `data_license` (full literal value set:
`"Yes"` 1437, `NA` 244, `"No"` 99, `"Unsure"` 80 [excluded — neither
positive nor negative], `"Yes, but not for all data archived"` 1
[excluded as ambiguous for this strict boolean test]) — this is the
presence/absence license column, distinct from `data_license_type`
(the specific license-kind field, e.g. CC0/CC BY, used separately in
the Dryad entry above). File: raw CSV →
`master_comparison$data_license` unchanged. Metacheck side:
`mc_data_license`, read from `repo_check$repo_metadata` scoped to
data-holding repositories (see construct-definitions entry above).

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
cases in this corpus to test specificity against (only 99 of 1292
both-coded papers), so a handful of scoping-mismatch disagreements move
this percentage a lot. The far more decision-relevant number here is
PPV (96.4%, reported in the Discussion) — when Metacheck DOES find a
license, it is very rarely wrong, since every METACHECK_RIGHT case was
independently reconfirmed against the same live platform API
`repo_check` itself reads from.

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

**Provenance.** Raw column: `data_download` (full literal value set:
`"Yes"` 1594, `NA` 243 [not asked — the sub-question only applies
when data was coded archived], `"Yes, but not all data"` 6 [folded
into positive], `"No"` 13, `"No, because the data are embargoed"` 5
[excluded — a distinct reason from a genuine download failure, not
comparable to Metacheck's technical download/parse test]). File: raw
CSV → `master_comparison$data_download` unchanged. Metacheck side:
`mc_data_download` (see construct-definitions entry above — requires
`tabular_usable == TRUE` AND non-missing `file_location` together,
read from `res_data_check$structure`).

**Formula.** Standard template above; this construct's disagreement
count is small enough (14) that every case was individually traced by
name rather than summarized into cause buckets.

**Relation to Cooper.** Direct comparison against Cooper's
`data_download` column. The `DIFFERENT_DEFINITION` cases here have a
precise, structural cause: `mc_data_download`'s criterion additionally
requires `data_check`'s stricter `tabular_usable` flag, which does not
always agree with "a human can open this file just fine in standard
software" (Cooper's own operational wording for this question, 2026,
§2.1.3, question 3: "whether the data/code files could be downloaded
at the time of investigation and, if so, whether they could be opened
using standard software") — the two sides can genuinely be asking
subtly different questions (machine-parseable-as-a-table vs.
human-openable-in-any-standard-program) even when both are being
applied correctly.

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

**Provenance.** Raw column: `code_archived` (full literal value set:
`"Yes"` 577, `"No"` 1092, `NA` 192 [where `code_used` was `"No"`
or `"Unsure"` — Cooper's protocol only asks this when code was coded
as used at all]). File: raw CSV →
`master_comparison$code_archived` unchanged. Metacheck side:
`mc_code_archived` (see construct-definitions entry above). Sub-cause
data: `code/03_comparing_results/disagreement_cause_categories.RData`'s
`cooper_right_causes$code_archived` and `code_archived_mr_causes`,
computed by `02_categorize_disagreement_causes.R` via a reproducible,
keyword-based pass over the worklist's own free-text verdict comments
(not hand-tallied).

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

**Provenance.** Raw column: `code_download` (full literal value set:
`"Yes"` 536, `"No"` 5, `NA` 1320 [legitimately not asked unless
`code_archived == "Yes"` by Cooper's own conditional protocol design —
matching the 577 `code_archived=="Yes"` papers closely, with the small
remaining gap being papers where this specific follow-up sub-question
itself was left unanswered]). File: raw CSV →
`master_comparison$code_download` unchanged. Metacheck side:
`mc_code_download` (see construct-definitions entry above).

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

**Provenance.** Two raw columns, combined: `data_README` (full literal
value set: `"Yes"` 1074, `"No"` 501, `NA` 213, `"Quasi-README"` 40,
`"Unsure"` 33 [excluded]) and `code_README` (full literal value set:
`NA` 1294 [code_archived not Yes], `"Yes"` 343, `"No"` 214,
`"Quasi-README"` 10). The combination logic lives in
`01_comparison_data.R`'s `.cooper_bool()` call:
`data_readme_bool <- .cooper_bool(data_README, c("Yes",
"Quasi-README"), "No")`; same for `code_readme_bool`;
`cooper_any_readme <- TRUE if EITHER is TRUE, FALSE if both resolved
and neither is TRUE, NA only if BOTH are NA`. This derived column is
saved directly onto `cooper_vs_metacheck.rds` (not read fresh from the
raw CSV at manuscript-render time) — it is a genuinely constructed
Cooper-side variable, the only one in this whole comparison. Cooper's
own paper independently reports the un-collapsed, single-question
version of this same statistic for reference: "A README or equivalent
was present for 66% (n=1114) and 61% (n=351) of the papers with
archived data or code, respectively" (2026, Results §5) — her 1114/351
are NOT directly comparable to this entry's 1242/1726 (72.0%), since
hers are separate data-only and code-only percentages with different
denominators (papers with archived data/code specifically), while
`cooper_any_readme` is a single OR-combined signal compared against a
different, Metacheck-shaped denominator (`n_both_coded`, which also
requires `mc_any_readme` to be non-missing).

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

**Provenance.** Raw column: `code_annotation_scale` — Cooper's own raw
CSV field, a direct 1–10 human quality rating (literal value
distribution: `NA` 1318, `10` [88 papers], `8` [83], `9` [77], `7`
[69], descending to `1` [21]), defined in her own published protocol
exactly: "we recorded how good the code annotation was on a scale of
1–10, where 1=not annotated at all and 10=thorough annotation
throughout" (Cooper et al., 2026, §2.1.3, question 7); her own Results
independently report "the median code annotation quality score was 7
(range 1–10)" corpus-wide (543 rated papers) — a statistic this
manuscript does not reproduce directly, since this entry's own
`n_cooper_coded` (543) matches her rated-paper count exactly, confirming
the join is correct. File: raw CSV →
`code_annotation_scale` joined against `res_code_check$table`'s
per-file `comment_lines`/`code_lines` (Metacheck-internal, read from
the full module output, not the slim file, since this specific script
runs separately), aggregated to one row per paper. Computed by
`03_comparing_results/03_comment_quality_correlation.R`, saved to
`comment_quality_correlation.RData`.

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
to answer the quality question directly at all. Cooper's own paper
flags this specific variable's measurement caveat directly: "The...
code annotation quality (median=7, range=2–10) variables were less
consistent among data recorders (Supporting Information B: Figure S15).
These variables should therefore be interpreted with care" (2026,
Results, second paragraph) — meaning even Cooper's own ground truth
for this one construct has acknowledged inter-rater noise, a caveat
this manuscript's own interpretation below should be read alongside.

**Interpretation.** r=.20 (≈4% variance explained) is weak but not
zero — meaning comment *density* is a poor stand-in for comment
*quality*: a single well-placed sentence explaining a complex analysis
scores as excellent annotation on Cooper's human scale and as a single
line on Metacheck's mechanical count; ten lines of boilerplate counts
as heavily annotated by line count and would plausibly score poorly on
a human quality read. This is exploratory, not a causal or "which
measure is right" claim — a low correlation is not evidence either
measure is wrong, just that they answer different questions, and part
of the weak correlation may itself trace to the inter-rater
inconsistency Cooper's own paper flags for this specific variable.

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
that distinction visible to the reader. No raw Cooper CSV column
appears anywhere in this section's own provenance chain.

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

**Provenance.** No Cooper-side source — all three checks are purely
Metacheck-internal structural signals Cooper's protocol never recorded.
Data: `res_code_check$table` (9202 rows, one per analysed code file),
fields `loaded_files_missing`, `code_abs_path`, `code_setwd`,
`paper_id`, read directly by `04_free_extras_summary.R` (loading the
full module-output file, not the slim one, since this script needs
these specific columns the slim extraction omits). Output:
`free_extras_summary.RData`, read in `manuscript.qmd` as `fe`.

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

**Provenance.** No Cooper-side source. Data:
`res_code_check$table$comment_lines`/`code_lines`/
`percentage_comment`/`has_docstring`/`language` (Metacheck-internal),
read by `04_free_extras_summary.R`, output in `fe` (`free_extras_summary.RData`).
For reference, Cooper's own raw CSV codes a related but much coarser
concept — `code_annotation_scale`, a single 1–10 human judgment per
paper (used in the comment-quality-correlation entry above) — not a
line-level comment-density measurement; there is no raw Cooper field
this entry's own file-level counts derive from or are checked against.

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

**Provenance.** No Cooper-side source for any of the three checks
(Cooper's own `code_language` column records which language(s) a
paper's code uses, but not per-file package-loading structure, parse
validity, or version pinning — none of these three signals have a raw
Cooper counterpart). Data:
`res_code_check$table$library_max_between`/`language`/`file_location`/
`parse_error`; `res_code_check$summary_table$code_n`/
`code_version_pinned` (all Metacheck-internal), read by
`04_free_extras_summary.R`, output in `fe`.

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

**Provenance.** No Cooper-side source — entirely Metacheck-internal
diagnostics. Data: `res_data_check$findings` (34,799 rows);
`res_repo_check$naming_issues` (64,960 rows) and
`res_repo_check$summary_table$files_n` (for the denominator), all read
by `04_free_extras_summary.R`, output in `fe`.

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

**Definition/Provenance/Formula.** Reuses `results` (already loaded,
already verified above, itself traceable through the same
`01_compute_comparison_statistics.R` → `comparison_statistics.RData`
chain documented at the top of the Empirical Comparison section)
directly — `lapply(names(results), function(nm) data.frame(Construct=r$label,
n=r$n_both_coded, ...))`, no new computation, no new raw-data read.

**Relation to Cooper.** Each row IS one of the six direct Cooper
comparisons detailed above, against the six raw CSV columns already
named in each construct's own entry — this table adds nothing new, it
just re-presents the same six numbers in one place.

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

**Provenance.** No new raw data — six already-existing fields, each
already traced to its own raw Cooper column in that construct's own
entry above, read together from `results`
(`comparison_statistics.RData`).

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

**Provenance.** The intermediate percentages (66.2%, 89.7%) are fixed,
point-in-time historical facts about an earlier state of the
corpus/codebase — not re-derivable from any current object, the same
way a lab notebook's dated entry isn't recomputed later; no raw file
or script currently reproduces them. Only the CHAIN'S FINAL value
(99.5%) is a live, current statistic (`results$code_download$pct_agree`,
traced to Cooper's raw `code_download` column in that construct's own
entry above).

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
(not a live corpus statistic that recomputes at render time), and
**no raw Cooper CSV column is involved at any point** — Cooper's own
protocol has no equivalent "actually execute the code" question at
all (see each entry's own "Relation to Cooper" below). Verified ~25
distinct claims directly against the surviving data files
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

**Provenance.** No Cooper-side source. Data:
`out$results$summary_table` (1861 rows, one per paper) and
`out$results$table` (4,394 rows, one per script attempted) —
Metacheck's `reproducibility_check` module's own output, produced by
`code/data/reproducibility_check/run_reproducibility_check.R`, saved
to `code/data/reproducibility_check_results.RData`.

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

**Definition/Provenance/Formula.** No Cooper-side source for any of
these counts. See each count's own direct tabulation against
`out$results$table`'s `error_type`/`not_runnable_reason` fields,
`summary_table$repro_deps`, and
`reproducibility_detail$all_matches$confidence`/`plausible_split` (a
separate extraction file, `reproducibility_detail.RData`, built by
re-parsing each paper's saved checkpoint text since the structured
summary table doesn't retain package-level failure detail) — all
Metacheck-internal `reproducibility_check` output, same source file as
the entry above.

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

**Provenance.** The 230 starting from `data_archive`-coded "Other
repo/database"/"Personal website"/"Supplementary materials" papers
(Cooper's own raw column, same `data_archive` field used throughout
this whole manuscript, defined in her own paper as the catch-all for
"institutional or governmental repositories, or specific projects") —
whose disagreement with Metacheck's `mc_data_availability` was already
established upstream. The review itself, and every category assigned,
comes from
`code/03_comparing_results/repo_not_detected_categorization.csv` (267
rows currently) filtered against two hardcoded 40-id and 9-id lists —
the primary record of individual human review, not derived from any
raw Cooper field beyond identifying which papers to look at.

**Formula.** `a9_cats <- a9_full[a9_full$article_id %in% a9_new_ids,
]`, matched back into the original id order for display.

**Relation to Cooper.** Each row's `category` field is the final,
individually-verified answer to "was this disagreement with Cooper
caused by a genuinely unsupported platform, a confirmed software bug on
an already-supported one, or something else (a bioinformatics
accession, withheld data, a text-extraction artifact)" — the most
fine-grained possible resolution of a Cooper-vs-Metacheck disagreement
in this entire manuscript, ultimately tracing back to the same
`data_archive` raw column discussed in the Methods-section entries
above.

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

## Session log and complete fix list

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

A second pass added full provenance to every entry: traced each
Cooper-side number back to its raw CSV column (confirmed the exact
literal value set and any recoding rule against both the live CSV and
Cooper et al.'s own published methods text, *Methods in Ecology and
Evolution* 2026, 17:1954-1966), and traced every Metacheck-side number
through its derivation script to the final manuscript variable. This
surfaced several places where a value this manuscript reports and a
superficially similar value Cooper's own paper reports are NOT the
same statistic despite sounding alike (flagged explicitly in each
affected entry's "Relation to Cooper" field) — for example, this
manuscript's Dryad-CC0 repository count is not her paper's
CC0-licensed-paper count (`data_license_type`); this manuscript's
`any_readme` agreement rate is not her separate data-README/code-README
percentages; this manuscript's `.tif`/`.shp` per-file classification
check has no counterpart in her paper at all, since her own coding
never goes to the individual-file level.

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
  simulated and confirmed correct. (Note: this memory constraint was
  later fully resolved by the render-efficiency rework described
  below — `manuscript.qmd`'s `data` chunk now reads
  `manuscript_data_slim.RData` instead of the two large files
  directly, and a subsequent full render completed successfully.)
- Cross-checked every raw Cooper CSV column named anywhere in this
  document against `table(cooper[[col]], useNA="ifany")` on the live
  `BES-data-code-hackathon-cleaned_2025-12-01.csv` directly, and
  cross-checked every literal percentage attributed to Cooper et al.'s
  own published paper against the actual PDF text (*Methods in Ecology
  and Evolution*, 2026, 17:1954-1966) rather than from memory or an
  earlier draft of this audit.

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
