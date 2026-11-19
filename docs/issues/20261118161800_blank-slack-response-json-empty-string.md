# Blank Slack acknowledgement JSON empty string

## Participants

Andrei Makarov

## Decisions

- Root cause sits in this library's `blank_slack_response!` under Grape JSON format, not in Slack modal open itself.
- Ship the acknowledgement as a raw empty body; do not JSON-encode an empty string.

## Effects

- Fix landed in `blank_slack_response!` (`api_format :txt` before `body false`). Engineering note: `docs/changelogs/20261118161800_blank-slack-response-json-empty-string.md`.
- Focused Grape extension and Schema specs pass with empty-body expectations.

## Next

- Review and cut a patch release.
- After release, consumers can remove local `blank_slack_response!` overrides.

## Source

- `docs/changelogs/20261118161800_blank-slack-response-json-empty-string.md`
- `lib/slack_bot/grape_extension.rb`
