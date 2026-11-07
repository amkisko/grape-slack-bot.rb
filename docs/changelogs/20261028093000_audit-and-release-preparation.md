# Audit fixes and release preparation

## Decisions

- Cut patch 2.1.3 for HTTP status and retry handling fixes.
- Reject end of input at the release confirmation prompt while accepting an entered empty line or yes.
- Return HTTP 401 for failed Slack signature verification. Keep application errors on the existing response path.
- Clamp a negative Retry-After value to zero before the bounded retry.
- Start quality, test, and coverage jobs for pull requests; give the test workflow read-only contents permission.

## Effects

- Signature request specs failed in five cases before the HTTP status fix and passed afterward.
- The negative Retry-After spec failed before the clamp and passed afterward.
- The release confirmation spec failed before the helper was added and passed afterward.
- Updated CHANGELOG.md, the version constant, and path-gem lockfile entries.

## Next

- Review the changes and publish only after the normal clean-tree release gate passes.

## Source

- lib/slack_bot/grape_extension.rb
- lib/slack_bot/api_client.rb
- usr/bin/release.rb
- spec/slack_bot/grape_extension_spec.rb
- spec/slack_bot/api_client_spec.rb
- spec/release_confirmation_spec.rb
