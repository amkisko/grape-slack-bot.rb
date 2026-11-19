# Blank Slack acknowledgement JSON empty string

## Participants

Andrei Makarov

## Decisions

- Treat Slack acknowledgement as HTTP 200 with a zero-length body, not a JSON-encoded empty string.
- Fix `blank_slack_response!` by switching `api_format` away from JSON before `body false`, matching the path already used by `empty_slack_ack!`.
- Keep `empty_slack_ack!` as a thin alias so Schema handlers keep the same call site.

## Effects

- Under Grape with `format :json`, `body false` sets an empty string that the JSON formatter encodes as `""`. Slack can show that as a blank ephemeral message while still opening a modal via `views.open`.
- Local probe on Grape 4.0.0: endpoint with `body false` and `status 200` returned body bytes `""` (two quote characters) and `Content-Type: application/json`. With `api_format :txt` first, the body length was zero.
- Specs that locked the encoded body (`eq('""')`) now expect `be_empty`.

## Next

- Shipped in 3.0.1. Consumers can drop local overrides of `blank_slack_response!` after upgrading.

## Source

- `lib/slack_bot/grape_extension.rb`
- `spec/slack_bot/grape_extension_spec.rb`
- Grape `DSL::InsideRoute#body` / `#api_format`
