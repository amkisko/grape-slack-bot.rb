# Testing

## Commands

Full suite (parallel shards via Polyrun):

```bash
make test
```

Lint (RuboCop and RBS):

```bash
make lint
```

Focused runs:

```bash
bundle exec rspec spec/grape_slack_bot/
```

See [POLYRUN.md](../POLYRUN.md) and `polyrun.yml`. `make test` runs `hooks.before_suite` before specs.

## Layout

- `spec/` — command parsing, middleware, and Slack payload specs

## Guidelines

- Test command routing and response contracts, not Slack client internals.
- Mock HTTP and Slack API boundaries only.
- Add or update specs before bugfixes; run `make lint && make test` before a PR.
- Local `make test` uses five workers; CI matrix uses one worker for stability. CI runs a separate `coverage` job with `POLYRUN_COVERAGE=1`; threshold in `config/polyrun_coverage.yml`.
