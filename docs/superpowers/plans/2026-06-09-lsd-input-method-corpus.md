# LD input-method corpus & predictive model — Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans or subagent-driven-development. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Build a private LD words+grammar corpus from the documents and export a generic, filtered predictive model (`lsd-model.sqlite`) for the native keyboards, with a tested Python reference engine.

**Architecture:** A standalone Python pipeline in a **new private repo `lsd-corpus`**: `ingest` (sources→plain unvocalized tokens, reusing font-fatemi's recovery modules) → `build` (private words/n-grams/grammar) → `filter` (→ generic SQLite) → `predict` (reference engine). Only `lsd-model.sqlite` leaves the repo.

**Tech Stack:** Python 3 (stdlib + the font-fatemi `ocr/` modules vendored), SQLite, pytest. Runs in the existing `lsd-ocr` Docker image (has fitz/freetype/fonttools).

---

### Task 1: Create the private repo + scaffold
**Files:** new repo `lsd-corpus`; `README.md`, `.gitignore`, `pipeline/`, `data/` (gitignored raw), `tests/`.
- [ ] Create private repo: `gh repo create abdealikhurrum/lsd-corpus --private --clone`
- [ ] `.gitignore`: `data/`, `out/full/`, `__pycache__/`, `*.sqlite-journal`. (Ships nothing private.)
- [ ] Vendor the recovery modules from font-fatemi into `pipeline/vendor/`: `legacy_decode.py`, `normalize.py`, `fonts.py`, `double_press_convert.py`, + the two fonts (for legacy_decode). Add a `sync_vendor.sh`.
- [ ] README: privacy boundary (only `out/lsd-model.sqlite` is shippable), how to run.
- [ ] Commit.

### Task 2: `pipeline/ingest.py` — sources → plain unvocalized tokens
**Files:** Create `pipeline/ingest.py`; Test `tests/test_ingest.py`.
- [ ] Test: `tokenize("اَلْبَيَانُ مِنَ الْإِيمَان")` → `["البيان","من","الايمان"]` (iʿrāb stripped, NFC). Run, see it fail.
- [ ] Implement: `normalize_text` (NFC + strip tatweel/invisibles via `normalize.normalize`, then `normalize.strip_vocalization`); `tokenize(text)` → split on whitespace/punct, keep Arabic-script tokens (drop pure-Latin/digits). `ingest_paths(paths)` yields `(doc_id, [tokens])`: `.txt`→read; `.docx`→zip/xml; PDF→presentation-form NFKC OR `legacy_decode` if legacy font detected.
- [ ] Run tests → pass. Commit.

### Task 3: `pipeline/build.py` — private corpus artifacts
**Files:** Create `pipeline/build.py`; Test `tests/test_build.py`.
- [ ] Test: building from two fake docs yields `words` with correct freq, `bigrams` with `(w1,w2)` counts, and `doc_count` per word (document spread). Run → fail.
- [ ] Implement: accumulate `words[word]=freq`, `docfreq[word]=#docs`, `bigrams`, `trigrams` (Counters). Affix analysis: top prefixes/suffixes by frequency over the word list → `grammar["prefixes"]`, `["suffixes"]`. `grammar["letters"]` = distinct extended letters seen. `grammar["confusions"]` = static rules (heh ہ↔ه, yeh ے↔ي) + double-press leftover patterns. Write `out/full/words.tsv`, `bigrams.tsv`, `trigrams.tsv`, `grammar.json`.
- [ ] Run tests → pass. Commit.

### Task 4: `pipeline/filter.py` — generic shippable SQLite
**Files:** Create `pipeline/filter.py`; Test `tests/test_filter.py`.
- [ ] Test: given words with freqs + docfreqs, words below `MIN_FREQ` or below `MIN_DOCS` (proper-name proxy) are dropped; remaining get integer `rank` buckets (log-scale); SQLite has `words`, `ngrams`, `rules` tables. Run → fail.
- [ ] Implement: drop `freq < MIN_FREQ` (default 3) and `docfreq < MIN_DOCS` (default 2); `rank = max(1, round(log2(freq)))`; keep n-grams with `docfreq >= NGRAM_MIN_DOCS` (default 3), cap to top `N`; write `lsd-model.sqlite` (`words(word TEXT, rank INT)`, `ngrams(prev TEXT, next TEXT, rank INT)`, `rules(kind, frm, to)`). Print full-vs-filtered counts + drop stats.
- [ ] Run tests → pass. Commit.

### Task 5: `pipeline/predict.py` — reference engine + spec
**Files:** Create `pipeline/predict.py`, `pipeline/model.md`; Test `tests/test_predict.py`.
- [ ] Test: on a fixture SQLite — `complete("سيد")` returns `سيدنا` ranked first; `next_word("مملوك","سيدنا")` backs off trigram→bigram→unigram; `autocorrect("اللہ")` (wrong heh) returns `الله`. Run → fail.
- [ ] Implement: `Model(path)` loads SQLite; `complete(prefix, n=5)` (rank-ordered prefix scan), `next_word(prev1, prev2=None, n=5)` (trigram→bigram→unigram backoff), `autocorrect(word, n=3)` (in-dict? else edit-distance≤1 candidates + apply `rules` confusions, rank). `model.md` documents the schema + algorithms for native ports.
- [ ] Run tests → pass. Commit.

### Task 6: Run on the real corpus + report
**Files:** `pipeline/run.sh`.
- [ ] `run.sh`: ingest the available sources (the harvested `corpus_all.txt` + AlFatemi PDFs + intellectual_dynamism) → build → filter → print report.
- [ ] Run in the `lsd-ocr` Docker image over the sources; report: token/word counts, full vs filtered model size, rare/proper-name drop counts, and sample completions / next-words / autocorrections.
- [ ] Commit `lsd-model.sqlite` to the repo (it's the generic, shippable artifact). Done.

## Self-review
- Spec coverage: ingest✓(T2) build✓(T3) filter/obfuscate✓(T4) engine+spec✓(T5) testing✓(T6) privacy✓(T1 .gitignore + private repo). 
- Thresholds (MIN_FREQ/MIN_DOCS/etc.) are explicit defaults, tunable in T6.
- No placeholders; types consistent (`words`/`ngrams`/`rules` schema used in T4 and T5).
