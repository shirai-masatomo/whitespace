# TODO

Tasks are intentionally small. Mark an item complete only after implementation, test, correction if needed, and retest are done.

## Ready

- [x] Create baseline project workflow docs: `SPEC.md`, `ACCEPTANCE.md`, and `TODO.md`.
- [x] Verify current app behavior manually in the browser.
- [x] Add lightweight automated tests for `normalizeInput` and intent matching.
- [x] Extract intent matching logic from `App.jsx` into a small testable module.
- [x] Create a 100-500 item review-only intent candidate dictionary.
- [ ] Review the expanded intent dictionary candidates in `docs/INTENT_DICTIONARY_REVIEW.md`.
- [ ] Review and tune the first-pass balance of tension, trust, and remaining utterances.
- [ ] Decide whether to keep or remove the old root-level browser-only React files.

## Backlog

- [ ] Add more nuanced response variants per intent.
- [ ] Add a visible debug panel for development only.
- [ ] Add app-level save/export of play transcripts.
- [ ] Explore a later LLM-backed response mode without changing the local rule-based mode.
