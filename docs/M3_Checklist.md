# M3 Checklist

Source: `docs/Godot_Development_Plan.md`

## Done / Started

- Local helper service prototype exists at `helper/DeskMochi.Helper`.
- Helper exposes local HTTP endpoints:
  - `GET /health`
  - `GET /events?last_id=<id>`
- Privacy-preserving keyboard activity sampling is implemented as key frequency only; key contents are not recorded or emitted.
- Git push-like event detection is implemented by watching local remote-ref logs for a configured repository.
- AI token log parsing is implemented for common `tokens`, `token_count`, and `total_tokens` lines.
- Helper supports JSON configuration with command-line overrides.
- Godot persists the helper event endpoint in user settings.
- Godot polls the helper through `scripts/integration/helper_event_client.gd`.
- Helper events map back into mochi feedback:
  - `keyboard_activity` -> blue energy ring and small sparks.
  - `git_push` -> green celebration burst.
  - `token_usage` -> purple charge pulse.
- Helper build, parser self-test, and HTTP health check are included in `Validate.cmd`.

## Remaining

- Manual runtime smoke with helper enabled and Godot running.
- Add a friendlier in-app settings surface for helper endpoint, monitored Git repo, and token log path.
- Replace Git remote-ref heuristic with a more explicit push event source if real-world repos prove inconsistent.
- Decide whether keyboard monitoring should be opt-in per launch, persisted preference, or installer-time permission.

## M3 Exit Criteria

- Fast typing triggers visible energy/star feedback without recording key content. Implementation exists; manual runtime smoke is still needed.
- Git push triggers celebration feedback. Heuristic implementation exists; manual smoke on a real repo is still needed.
- Token log growth triggers charge feedback. Parser and Godot mapping exist; manual smoke with a real agent log is still needed.
- Helper service does not block the Godot process. Godot polling is optional and silently retries when helper is absent.
