## Problem

`data_classify_files()`'s Tier 2 (the keyword-in-path fallback, used for every extension without a Tier-1 format-locked rule -- including every image format, plain `.txt`, and anything else not yet added to `.ext_registry`) has two related weaknesses, both confirmed live against real corpus files:

**1. No provenance is recorded.** Once the function returns `"data"`/`"materials"`/`"code"`/`"output"`/`"unknown"`, there is no record of *which* tier, or which specific keyword rule, produced that value. A Tier-1 format-locked `"data"` (high confidence: the extension itself is unambiguous evidence) is indistinguishable, downstream, from a Tier-2 keyword collision (much lower confidence: the word merely appeared somewhere in the path) or a Tier-3 coarse-crosswalk fallback (lowest confidence: no path signal fired at all, and the result is just "images are usually materials"). This makes every misclassification undiagnosable without reverse-engineering the source, which is how long this specific investigation took.

**2. Tier 2 matches a bare, unbounded keyword occurrence anywhere in the full path, not "does this file actually live in a folder whose purpose is data storage."** Confirmed live:

```r
metacheck::data_classify_files("photo_specimen.tif", "raw_data_photos/photo_specimen.tif")
# "data" -- an ordinary photograph, classified as data purely because
# the literal substring "data" appears in a folder name used for an
# unrelated purpose (a folder of specimen photos, not a data folder)
```

This is a real risk specifically because `.tif`/`.tiff` (and every other image format, and every format not yet added to Tier 1) have **no format-locked rule at all** -- their classification rests entirely on this keyword collision, with no fallback content check. The same corpus that surfaced this also shows the opposite failure: a real data folder named with a compound word (`ShapefilesAndData`, no separator before "Data") is *not* rescued by the keyword rule at all, because the token-boundary regex correctly refuses to match "data" as a bare substring of "ShapefilesAndData" (to avoid a different, opposite false-positive class, e.g. "metadata.csv") -- so the same boundary strictness that prevents one error class silently causes the other.

## Why this specifically matters for the tool's actual goal

If the goal is to reliably retrieve which files in a repository are the paper's real, usable research data, this mechanism produces two symmetric failure modes with no way to tell them apart after the fact:

- **False positive**: a file that is not really data (a stimulus image, a specimen photograph, a screenshot, a figure export) gets counted as `data` because of an incidental word match somewhere in its path. This artificially inflates apparent data-sharing/data-completeness and could mislead a downstream consumer (a meta-scientific audit, a FAIR-ness scorer, or a researcher relying on metacheck's own file listing) into treating a non-data file as the paper's actual dataset.
- **False negative**: a genuine data file (Shapefile components, a `.tif` GIS raster, any other format without a Tier-1 rule) sitting in a folder whose name does not happen to contain a matching keyword -- or contains it in a form the boundary regex does not recognise -- is typed `unknown` or `materials`, silently undercounting what the paper actually shared.

Both failure modes are corpus-confirmed, not hypothetical (see the linked issue #441 for the aggregate counts: 56% of real `.shp` files, and a nontrivial share of real `.tif` files, are affected one way or the other).

## Proposed redesign

**1. Record classification provenance.** Extend `data_classify_files()`'s return value (or add a parallel output) to carry which mechanism produced the result: `"tier1_format_locked"`, `"tier2_keyword:<rule_pattern>"`, `"tier3_crosswalk"`, or `"unresolved"`. This is the single highest-leverage change: it costs little (the information already exists inside the function, it is just discarded before returning), and it turns every future misclassification into something diagnosable in one glance rather than requiring a fresh investigation each time, and lets any downstream consumer (including `data_check`'s own report) distinguish high-confidence from low-confidence classifications, or filter/flag low-confidence ones for review.

**2. Narrow Tier 2 to whole path *segments*, not a boundary-token match against the full path string.** Currently a keyword only needs to appear as a bounded token anywhere in the (possibly deep) path. Restricting the match to an entire path segment (the text between two `/`, e.g. requiring the segment itself to equal `"data"` or start with `"data_"`/`"data-"`, rather than merely containing that token anywhere within a longer segment) would directly prevent the `raw_data_photos/` false positive above, since `raw_data_photos` is one compound segment, not a segment that IS "data". This does trade off against catching genuinely well-named folders like `ShapefilesAndData` (which would still not match) -- see point 4.

**3. Add a real content-based check before trusting the Tier-3 image->materials crosswalk.** This is the concrete fix for the `.tif` case specifically: before falling back to "images are materials," check for GeoTIFF/georeferencing signatures (embedded CRS tags, a `.tfw`/`.aux.xml` sidecar file, or a companion `.prj`) as a genuine, content-based signal that the image is a GIS data raster rather than a photograph or stimulus. This is strictly stronger evidence than any path keyword, and directly resolves the exact ambiguity you raised: an ecology GIS raster and a psychology stimulus image are the same file format but need different classifications, and only the file's own content (not its folder name) can reliably tell them apart.

**4. Treat "no keyword matched" as its own distinct, informative outcome rather than folding it into the same `unknown` bucket a genuinely unrecognised extension gets.** Right now a Shapefile with no informative folder name and a file whose *extension itself* metacheck has simply never seen both end up `unknown`, indistinguishable from each other. If point 1 (provenance) is implemented, this is already partly solved; additionally, for extensions in the Tier-1-worthy list identified in #441 that are not yet added there, adding them removes this ambiguity entirely for those formats going forward.

**5. Document the Tier 2 rule-order decision explicitly**, including why `materials|stimuli|stimulus` is checked before `data` (so a stimulus-and-data folder resolves to materials, evidently a deliberate choice already) -- so future edits to this list are checked against a stated rationale instead of silently reordering behaviour for unrelated formats.

## Relationship to #441

#441 proposes adding specific missing extensions (Shapefile, phylogenetic trees, etc.) to Tier 1 -- a targeted, low-risk fix for formats where the extension alone is unambiguous. This issue is the complementary, structural fix: even after #441 lands, every OTHER format without a Tier-1 rule (images foremost among them) remains exposed to the keyword-collision problem described here, so the underlying mechanism itself needs the redesign proposed above, not just more Tier-1 entries.

## Context

Found while investigating a `.tif` classification question in a manuscript comparing metacheck against Cooper et al.'s human-coded validation corpus of 1861 BES journal papers -- the same investigation that produced #441. Confirmed against `metacheck` 0.3.1, commit `5af3162`.
