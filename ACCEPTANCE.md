# ACCEPTANCE

This file defines the acceptance criteria for the current milestone.

## Completed Milestone: Stabilize `宥めよ` Prototype Workflow

The milestone is complete when all criteria below are satisfied.

- Required project docs exist: `PROJECT_STATE.md`, `SPEC.md`, `ACCEPTANCE.md`, and `TODO.md`.
- App-specific history exists at `prototypes/001-nadameyo/APP_STATE.md`.
- Command history exists at `docs/COMMAND_LOG.md`.
- `prototypes/001-nadameyo` can pass lint.
- `prototypes/001-nadameyo` can pass production build.
- The local dev server can return HTTP `200`.
- TODO items are updated only after the related acceptance criteria pass.
- Each milestone update is committed to Git.

## Current Milestone: Prepare A Reviewable Intent Dictionary

- The intent dictionary is outside `App.jsx` in a structured data file.
- The dictionary contains between 100 and 500 expression candidates.
- Every expression has `text`, `intent`, `subtype`, `confidence`, and
  `sourceType`.
- Ambiguous expressions are marked `medium` or `low` with explanatory notes.
- Only explicitly adopted expressions affect gameplay.
- Existing intent order, replies, and trust/tension changes remain unchanged.
- A generated review list exists at `docs/INTENT_DICTIONARY_REVIEW.md`.
- Source and license notes distinguish verified dictionary entries from generated
  candidates.
- Automated tests cover dictionary metadata, normalization, active-entry
  filtering, existing behavior, and review-only behavior.
- Tests, lint, production build, and browser behavior verification pass.

## Current App Behavior Acceptance

- The page shows `宥めよ`.
- The page shows tension, trust, and remaining utterances.
- The player can enter and submit one sentence.
- Apology-like input such as `ごめん` and `すみません` raises trust.
- Listening-like input such as `聞かせて` raises trust.
- Command or rejection-like input such as `落ち着いて` and `知らない` raises tension.
- Unknown input raises tension mildly.
- Reaching maximum tension fails the run.
- Reaching the trust threshold succeeds the run.
- Running out of utterances fails the run.
- The player can restart after success or failure.
