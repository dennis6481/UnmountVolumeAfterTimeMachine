# Project Guidelines

## Preserve Existing Comments

- Preserve all comments written by the original author when modifying existing files.
- Do not remove or rewrite the original author header or existing TODO comments.
- Add a separate `Modified by <Author name> on <date>.` line for personal changes. If not created by me
- Only update or remove an existing comment after the behavior it describes has been verified as fixed; explain that change in the handoff.

## Do Not Hide Errors with Fallbacks

- Do not add a fallback implementation unless the user explicitly requests it or it is strictly necessary for correctness.
- During an experiment intended to validate a replacement implementation, record and surface errors from the replacement instead of silently falling back to the old implementation.
