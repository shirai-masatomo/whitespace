# SPEC

WhiteSpace is a prototype-first project for small interactive works. The current active prototype is `prototypes/001-nadameyo`, a text conversation game titled `宥めよ`.

## Active Prototype

- Path: `prototypes/001-nadameyo`
- Title: `宥めよ`
- Stack: Vite, React, local rule-based intent matching
- Runtime target: local browser

## Product Intent

The player can only move the situation by speaking, but every utterance carries risk. The first prototype should make this tension understandable through a very small loop: read the other person's line, choose one sentence, watch trust or tension change, and reach success or failure.

## Current Gameplay

- Show the directive `宥めよ`.
- Show tension, trust, and remaining utterances.
- Let the player submit one sentence at a time.
- Normalize input before matching.
- Match normalized input against intent rules.
- Change the other person's reply and state values based on the matched intent.
- End in failure when tension reaches the maximum.
- End in success when trust reaches the success threshold.
- End in failure when utterances run out.
- Let the player restart after success or failure.

## Intent Matching

Input matching uses intent categories instead of one-off word checks.

- `rejection`: raises tension strongly.
- `hostile`: raises tension strongly.
- `command`: raises tension.
- `apology`: raises trust.
- `listening`: raises trust.
- `reassurance`: raises trust.
- `unknown`: raises tension mildly.

Each intent has multiple words and one response payload. Details live in `prototypes/001-nadameyo/APP_STATE.md`.

## Documentation Rules

- `PROJECT_STATE.md` tracks repository-level state.
- `docs/COMMAND_LOG.md` tracks important command execution history.
- `prototypes/001-nadameyo/APP_STATE.md` tracks app-specific state, state transitions, specs, and change history.
- `TODO.md` tracks small actionable tasks.
- `ACCEPTANCE.md` tracks completion criteria for the active milestone.

