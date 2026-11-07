# Load benchmark and ApiResponse JSON hot path

## Participants

Andrei Makarov (@amkisko)

## Decisions

- Add `benchmarks/load.rb` using `Polyrun::Benchmark::Pressure` (vendored under `benchmarks/support/polyrun/benchmark/pressure.rb`) to stress Slack-style HMAC verification (`secure_compare` + `HMAC.hexdigest`) and in-process `Faraday::Response` handling with `SlackBot::ApiResponse` (multiple `#data` calls per response).
- Count synthetic request/response body bytes as `network_in_bytes` / `network_out_bytes` (sum of JSON byte sizes accumulated in the timed block).
- Pressure row: 1.5× reps, +4 KiB response bodies, +2 extra `#data` touches; gates only **heap Δ** and **alloc** from the baseline API row (`TARGET_FACTOR` default 0.85); wall/cpu and net bytes are not capped (payload growth is not a linear ops scaling).
- `make bench-load` runs `env -u BUNDLE_PATH bundle exec ruby benchmarks/load.rb` so a parent `BUNDLE_PATH` (sandbox gem tree) does not break `bundle exec` against this repo.
- Memoize `ApiResponse#data`: one `JSON.parse` per response instance; invalid JSON still returns the same fallback hash as before.

## Effects

### Harness

- `benchmarks/load.rb` + vendored `benchmarks/support/polyrun/benchmark/pressure.rb`
- `make bench-load`; JSON under `benchmarks/output/` (gitignored)
- Env: `SCENARIO=matrix|hmac|api`, `REPS` (default 400), `BODY_KB` (default 8), `DATA_TOUCHES` (default 4), `TARGET_FACTOR`, `SLACK_SIGNING_SECRET`

### Machine: `arm64-darwin24`, Ruby `4.0.2` (2026-11-06)

Default matrix (`REPS=400`, `BODY_KB=8`, `DATA_TOUCHES=4`):

| Row | Before (memoize) | After (memoize) | Δ |
| --- | ---: | ---: | ---: |
| baseline_hmac_verify wall | 0.0049s | 0.0047s | ~−4% |
| baseline_hmac_verify ops/s | 82220 | 84980 | +3% |
| baseline_api_response wall | 0.0252s | 0.0148s | ~−41% |
| baseline_api_response ops/s | 111204 | 188819 | +70% |
| baseline_api_response alloc | 25740 | 16141 | −37% |
| pressure_api_response wall | 0.0423s | 0.0306s | ~−28% |
| pressure_api_response ops/s | 127629 | 176702 | +38% |
| pressure_api_response alloc | 40805 | 22805 | −44% |

JSON artifacts:

- Before: `benchmarks/output/20261106153709_load.json`
- After: `benchmarks/output/20261106153716_load.json`

Host-relative only; not an SLO.

### Code

- `lib/slack_bot/api_client.rb`: memoized `#data`

## Next

- Optional: expose a tiny “no memo” path for tests that mutate `response.body` after construction (none in-repo today).

## Source

- `benchmarks/load.rb`
- `benchmarks/support/polyrun/benchmark/pressure.rb`
- `lib/slack_bot/api_client.rb`
