# AI Job Hunter contribution guide

## Scope and safety

- Preserve existing behavior and do not modify unrelated files. Inspect `git status` and `git diff` before and after work.
- Ask before destructive, irreversible, or broad changes. Never delete or reset user work without explicit approval.
- Never hardcode secrets, tokens, API keys, credentials, or private endpoints. Use secure configuration only when it is explicitly introduced.
- Do not invent APIs, backend behavior, authentication flows, or data contracts. Mark missing product decisions as **AMBIGUOUS — requires product decision**.

## Flutter and architecture

- Follow idiomatic null-safe Dart, `const` constructors where appropriate, small focused widgets, and clear immutable models.
- Keep presentation, domain, and data concerns separate. UI must depend on abstractions, not API clients or persistence details.
- Prefer composition over large monolithic screens. Extract genuinely recurring UI into reusable widgets; keep feature-specific widgets local.
- Centralize theme tokens, strings that are reused, route names, and asset references. Avoid magic values where a named design token is clearer.
- Keep state predictable and scoped to the feature. Use loading, empty, error, disabled, and selected states deliberately when designs require them.

## Design fidelity

- The Visily PDFs in `design/` are the visual source of truth. Reproduce their hierarchy, copy, spacing, colors, controls, selected states, and responsive intent before adding interpretation.
- Do not redesign screens or substitute UI patterns without a documented product decision.
- When a detail is not visible or is contradictory, record it as **AMBIGUOUS — requires product decision** rather than guessing.

## Dependencies and quality

- Add a package only after checking that Flutter/Dart built-ins cannot reasonably cover the need; document its purpose and maintenance/security implications.
- Do not add, upgrade, or remove dependencies without scoped authorization.
- Add or update tests for behavior that changes. Favor widget tests for UI and unit tests for models, state, and repositories.
- Run `dart format`, relevant tests, and `flutter analyze` before handing off implementation work; report failures rather than hiding them.

## Git hygiene

- Keep changes small, reviewable, and limited to the requested scope.
- Do not stage, revert, rewrite, or discard unrelated changes. Do not use forceful Git operations unless explicitly asked.
