# iOS Keyboard — Research Notes & TODO

## Pyramidal key depth cue

### Idea
Physical keyboards (BlackBerry, Clicks, Unihertz Titan) angle each key face toward the
approaching thumb.  The angle gives a tactile registration cue and a visual affordance.
The question is whether a software equivalent — a visual-only depth cue — can guide
subconscious placement the same way.

### Implementation (current)
Each key is drawn as four flat triangles meeting at the key centre (`KeyButton.draw(_:)`).
Each facet is a constant-shade black overlay on the base key colour, producing hard ridges
between faces — the "pyramidal" look.

Shading model:
- **Top face** — always darkest (back face, away from viewer)
- **Bottom face** — always clear (front face, toward viewer)
- **Left face** — scales 0 → `base` as `colIndex` goes left → right
  (bright for left-thumb keys, dark for right-thumb keys)
- **Right face** — inverse of left

Row intensity varies 0.18 → 0.12 top-to-bottom, reflecting the steeper physical tilt of
upper rows on a curved keyboard body.

Controlled by `KeyboardSettings.angledKeysEnabled` (default on).  Toggle accessible from
the main app ("Keyboard Appearance") and from the in-keyboard settings panel.

### What the corpus data says (baseline, 2026-05-26, pre-gradient)
Touch offsets (`CorpusLogger`) already show **positive meanDy on almost every key** —
thumbs naturally land below key centre.  This is consistent with the bottom face being the
"highlight" direction.

Horizontal pattern: right-side keys (ه، م، و، ن) show **positive meanDx** — users
consistently tap right of centre on right-thumb keys.  The pyramid puts the highlight at
lower-right for those keys, which may reinforce the rightward drift rather than correct it.
Watch this in the next export.

### Measuring efficacy
`CorpusData` now stores:
- `offsets[key].meanDy / stdDy` — placement mean and standard deviation per key
- `corrections[key]` — immediate-backspace count
- `snapshotConditions[date]` — whether `angledKeysEnabled` was on that day

**Signal to look for:** `stdDy` decreasing in the `angledKeysEnabled = true` snapshots
relative to the baseline days.  Mean shift alone is weak; tighter distribution is the
stronger signal that a subconscious cue is taking effect.

### Research context
No published work addresses per-key directional visual cues of this kind for touchscreen
thumb typing.  Adjacent findings:

- **Skeuomorphic depth cues** reduce errors for novice users but the effect diminishes as
  muscle memory forms (Abzug & Filz, 2013).  The goal here is the opposite: accelerate
  muscle-memory formation rather than substitute for it.
- **Directional affordances guide motor preparation** before contact (Gibson, ecological
  affordances; action-specific perception literature).  This is the theoretical basis.
- **Touch landing points are biased by visual targets** — users do not press the visual
  centre of keys (Holz & Baudisch, CHI 2010).  The corpus baseline confirms this.

---

## Keyboard layout and key count

### What is well-established

**FFitts Law (Bi, Li & Zhai, CHI 2013)** — error rates on touchscreen targets degrade
*non-linearly* below a threshold size.  On a standard iPhone in portrait (~375 pt usable
width), 11 keys per row produces roughly 30–32 pt key width.  Apple's HIG minimum is 44 pt.
The LSD keyboard operates below this on every character key — unavoidable given 28 Arabic
base letters, but it means the keyboard is in the steep part of the FFitts curve.

**KALQ (Oulasvirta et al., Max Planck / CHI 2013)** — computational optimisation of a
two-thumb split layout for tablet typing reached 37 WPM.  Their optimal layout used
**6 keys per thumb half (12 total)**, not 22+.  Conclusion: fewer, larger keys compensate
for lost QWERTY familiarity because accuracy gains outweigh slower mental lookup.

**MacKenzie (1999, Behaviour & Information Technology)** — QWERTY beats ABC layout even on
stylus keyboards (20.2 vs 10.6 WPM).  Familiarity is a genuine transfer advantage; this
is why every major Arabic mobile keyboard (iOS, Gboard, SwiftKey) stays on the
QWERTY-mapped Arabic layout despite its PC heritage.

### The Arabic/Urdu gap
**No published peer-reviewed research exists on Arabic or Urdu mobile keyboard layout
optimisation.**  Latin-character findings do not transfer cleanly:
- Arabic has contextual letter forms and diacritics that need to be accessible
- Letter frequency distribution differs (ي، ا، ل are extremely high frequency)
- Readers chunk by root patterns, not letter frequency alone

### What the corpus data suggests
The keys with the highest correction rates in the baseline data cluster on the edges of the
11-key rows, consistent with FFitts non-linearity:

| Key | Col | Corrections | meanDx |
|-----|-----|-------------|--------|
| ه   | 7/11 | 8 / 12 presses (67%) | +5.8 |
| س   | 1/11 | 6             | −1.5 |
| ك   | 9/11 | 4             | +1.2 |

Low-correction keys (و، ل، ر) sit in the middle of rows with more horizontal room.
This pattern is more informative than any general-purpose study for this specific layout.

---

## TODO

### Measurement
- [ ] Export corpus after ~5 days of typing with `angledKeysEnabled = true` and compare
      `stdDy` and `corrections` against the 2026-05-26 baseline snapshots
- [ ] Specifically watch ه: if corrections stay above 50 %, the highlight direction for
      col-7 right-side keys may need to be dampened or inverted

### Angled-keys feature
- [ ] Consider whether the pyramid intensity should be **per-key tunable** based on
      observed offset magnitude rather than a fixed row formula — keys with large meanDy
      (e.g. ؤ +9.0) could have stronger bottom-face highlight; keys already well-centred
      could be flat
- [ ] Evaluate haptic differentiation by row as a complementary (non-visual) channel —
      different UIImpactFeedbackGenerator styles per row to reinforce the spatial map
- [ ] Test pyramid contrast values (`base` = 0.18) on a physical Tier 2/3 device
      (low-DPI screen may make the ridges look coarse rather than intentional)

### Layout and key count
- [ ] Run an analysis on the corpus: plot correction rate vs. column index to confirm
      (or refute) the FFitts edge-key hypothesis
- [ ] Consider whether ه warrants a wider hit target or a position swap with a lower-
      frequency neighbour — the 67 % correction rate is too high to be purely a visual-cue
      problem
- [ ] The literature gap is an opportunity: if the corpus experiment shows a measurable
      effect of the pyramidal cue on Arabic thumb typing, it is publishable — no prior
      work exists on directional per-key depth cues for RTL scripts

### Performance
- [ ] Verify `layer.shadowPath` fix improves compositing performance on an older device
      (iPhone 8 or equivalent) using Instruments → Core Animation
- [ ] If `angledKeysEnabled = false` is the production default for Tier 3 users, consider
      detecting device capability (e.g. `ProcessInfo.processInfo.processorCount`) and
      defaulting accordingly — though the draw cost is negligible; the shadow was the
      actual concern and is now fixed regardless
