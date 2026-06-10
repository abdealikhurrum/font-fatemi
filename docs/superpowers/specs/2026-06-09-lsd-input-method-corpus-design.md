# LD input-method corpus & predictive model — design

**Date:** 2026-06-09
**Status:** approved (pending written-spec review)

## Goal

From private Lisān ud-Daʿwat (LD) documents, produce two things:

1. A **private** corpus of LD words + grammar (full, never shipped).
2. A **generic, filtered** predictive model in a portable format that the native
   input methods (iOS/macOS Swift keyboards, Android, Windows) can each consume,
   powering **prefix completion**, **next-word prediction**, and
   **autocorrect/spelling**.

All text is **plain / unvocalized** — iʿrāb is not used in LD input, so vowel
marks are stripped throughout (smaller, cleaner word list; one form per word).

Source documents and the full word list **stay private**. Only the filtered,
obfuscated model leaves the privacy boundary, to be copied into the keyboard
repos for shipping. The shipped model is generic LD vocabulary, not a fingerprint
of the source documents.

This round delivers the **data pipeline + portable model + a tested reference
prediction engine**. The per-platform keyboard engine/UI is a later round.

## Privacy boundary

- A **new private GitHub repo** (`lsd-corpus`, under the user's account) holds:
  recovered source text, build scripts, and the full unfiltered artifacts
  (`words.tsv`, `bigrams.tsv`, `trigrams.tsv`, `grammar.json`).
- Nothing private goes in the public `font-fatemi` or `abdealikhurrum.github.io`
  repos.
- The **only** artifact that crosses the boundary is the filtered
  `lsd-model.sqlite` (generic), exported into the keyboard repos.

## Architecture (single pipeline, four stages)

```
private docs ─▶ 1. ingest ─▶ 2. corpus build ─▶ 3. filter/obfuscate ─▶ lsd-model.sqlite
                (plain text)   (private full)      (generic, shippable)
                                     │
                                     └─▶ 4. reference prediction engine (Python, tested)
```

### 1. Ingest (sources → plain text)
Reuse the OCR project's recovery code (imported, not duplicated):
- Clean `.docx` (Drive harvest, araz): zip → logical-order text.
- Presentation-form PDFs (`intellectual_dynamism`): `normalize.fold_presentation_forms` (NFKC).
- Legacy AlFatemi PDFs: `legacy_decode` (FreeType glyph-matcher, ~90%).
- Per source: `normalize()` → NFC → strip tatweel/invisibles → **strip iʿrāb**
  (`normalize.strip_vocalization`) → word tokens.
- Keep per-document provenance (privately) for the document-spread filter in stage 3.

### 2. Corpus build (private, full)
- `words.tsv` — unvocalized word → frequency.
- `bigrams.tsv`, `trigrams.tsv` — unvocalized word sequence → frequency.
- `grammar.json`:
  - morphology: frequent prefixes (نو، نے، تہ، …) / suffixes, derived from
    affix-frequency analysis;
  - extended-letter inventory actually used (پ چ ٹ ڈ ڑ گ ں ہ ھ ے …);
  - confusion rules for autocorrect: Urdu↔Arabic heh (ہ/ه), yeh (ے/ي),
    leftover double-press sequences → Unicode (from `double_press_convert`).

### 3. Filter / obfuscate (→ shippable model)
- Drop words with frequency below a floor (rare/identifying).
- Drop likely proper names: low **document-spread** (a word appearing in very few
  documents is likely a name/title), optionally cross-checked against an honorific
  context list.
- Replace raw counts with **bucketed ranks** (log-scale) — no exact frequencies.
- N-grams: keep only those recurring across **many** documents (generic function-
  word sequences); drop document-specific phrases; cap total count.
- Emit `lsd-model.sqlite`: tables `words(word, rank)`, `ngrams(prev, next, rank)`,
  `rules(kind, from, to)`. Portable + queryable on every target platform.

### 4. Reference prediction engine (Python, tested here)
A documented algorithm + Python implementation the native ports mirror:
- **completion(prefix)** → top-N words by rank with that prefix (trie / sorted scan).
- **next_word(prev1, prev2)** → n-gram backoff (trigram → bigram → unigram).
- **autocorrect(word)** → if not in dictionary, candidates by edit-distance + the
  confusion rules, ranked.

## Components & interfaces

| Unit | Purpose | Input → Output |
|------|---------|----------------|
| `ingest.py` | sources → normalized plain-text tokens + provenance | doc paths → token streams |
| `build.py` | tokens → private corpus artifacts | tokens → `words/bigrams/trigrams.tsv`, `grammar.json` |
| `filter.py` | private artifacts → generic shippable model | full artifacts → `lsd-model.sqlite` |
| `predict.py` | reference engine over the model | model + context → suggestions |
| `model.md` | the portable format + algorithm spec | (doc) |

## Testing (this round, here)
- Run the pipeline on the harvested ~53k-line corpus.
- Report: token/word counts, model size (full vs filtered), proper-name/rare-word
  drop counts, and qualitative samples for each feature (completions, next-words,
  autocorrections).
- Unit tests for `predict.py` (completion/next-word/autocorrect) on a small
  fixture.

## Out of scope (next round)
- Per-platform keyboard engine code (Swift for iOS `LSDLearningKB` + macOS, etc.).
- Suggestion-bar UI; `CorpusLogger` on-device-learning wiring.
- Shipping/integrating the model into keyboard builds.
